[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$CsvPath,

    [Parameter()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$MockDirectoryPath = ".\examples\mock-directory-users.csv",

    [Parameter()]
    [string]$OutputDirectory = ".\output",

    [Parameter()]
    [ValidateSet("ValidateOnly", "PlanOnly", "SimulateApply")]
    [string]$Mode = "PlanOnly",

    [Parameter()]
    [string]$DomainName = "example.local",

    [Parameter()]
    [string]$TenantName = "Example Organization"
)

$ErrorActionPreference = "Stop"

# This demo keeps the shape of the original onboarding workflow without touching
# private systems. It reads an export, plans the account/access work, writes the
# reports, and simulates the apply step.

# Required columns from the outside export. Keeping this list explicit makes
# bad CSVs fail early instead of halfway through the workflow.
$RequiredColumns = @(
    "ExternalPersonId",
    "FirstName",
    "LastName",
    "Email",
    "Program",
    "Service",
    "TrainingLevel",
    "RotationStartDate",
    "RotationEndDate",
    "RotationLocation",
    "AccessType",
    "AccessId",
    "AccessPassword",
    "ActivationDate",
    "DeactivationDate",
    "Comments",
    "Status",
    "LicenseRequired",
    "TicketId"
)

# Map each access type to a report flag, a fake group, and a plain-English
# action. This is the part that turns messy CSV rows into planned IT work.
$AccessTypeMap = @{
    "Network Login" = @{
        Flag = "NeedsDirectoryAccount"
        Group = "GG-Training-Network-Login"
        Action = "Create or update directory account"
    }
    "Email" = @{
        Flag = "NeedsMailbox"
        Group = "GG-Training-Email"
        Action = "Enable or confirm mailbox"
    }
    "Clinical App" = @{
        Flag = "NeedsClinicalApp"
        Group = "APP-Clinical-Training-Users"
        Action = "Grant training app access"
    }
    "Shared Drive" = @{
        Flag = "NeedsSharedDrive"
        Group = "FS-Training-Shared-Drive"
        Action = "Grant shared drive access"
    }
    "VPN" = @{
        Flag = "NeedsRemoteAccess"
        Group = "VPN-Training-Users"
        Action = "Review remote access requirement"
    }
}

# Fake OU placeholders. They show the routing idea without exposing a real
# directory structure.
$ProgramOuMap = @{
    "Medical Education" = "OU=MedicalEducation,OU=Training,DC=example,DC=local"
    "Nursing Education" = "OU=NursingEducation,OU=Training,DC=example,DC=local"
    "Clinical Rotation" = "OU=ClinicalRotation,OU=Training,DC=example,DC=local"
    "Research" = "OU=Research,OU=Training,DC=example,DC=local"
}

function New-SafeDirectory {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Write-DemoLog {
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$Path,
        [ValidateSet("INFO", "WARN", "ERROR")]
    [string]$Level = "INFO"
    )

# Local log only. The original needed reviewable logs, but this demo does not
# touch shared drives or ticketing.
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -LiteralPath $Path -Value $line -Encoding UTF8
}

function Get-UniqueFileName {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][string]$BaseName,
        [Parameter(Mandatory)][string]$Extension
    )

    $candidate = Join-Path $Directory "$BaseName$Extension"
    $counter = 1

# Avoid overwriting older reports when the demo is run more than once.
    while (Test-Path -LiteralPath $candidate) {
        $candidate = Join-Path $Directory ("{0}-{1}{2}" -f $BaseName, $counter, $Extension)
        $counter++
    }

    return $candidate
}

function ConvertTo-CleanString {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return ""
    }

    return $Value.Trim()
}

function ConvertTo-DateOrNull {
    param([AllowNull()][string]$Value)

    $clean = ConvertTo-CleanString -Value $Value
    if ([string]::IsNullOrWhiteSpace($clean)) {
        return $null
    }

# Source exports are not always consistent about dates, so accept the common
# formats the workflow may see.
    $formats = @("yyyy-MM-dd", "M/d/yyyy", "MM/dd/yyyy", "dd-MMM-yy", "dd-MMM-yyyy")
    foreach ($format in $formats) {
        try {
            return [datetime]::ParseExact($clean, $format, [Globalization.CultureInfo]::InvariantCulture)
        } catch {
            continue
        }
    }

    $parsed = [datetime]::MinValue
    if ([datetime]::TryParse($clean, [ref]$parsed)) {
        return $parsed
    }

    return $null
}

function Format-DateValue {
    param([AllowNull()]$Date)

    if ($null -eq $Date) {
        return ""
    }

    if ($Date -is [datetime]) {
        return $Date.ToString("yyyy-MM-dd")
    }

    $parsed = ConvertTo-DateOrNull -Value $Date
    if ($null -eq $parsed) {
        return ""
    }

    return $parsed.ToString("yyyy-MM-dd")
}

function ConvertTo-BooleanText {
    param([AllowNull()][string]$Value)

    return (ConvertTo-CleanString -Value $Value) -match "^(yes|true|1|y)$"
}

function Test-BooleanText {
    param([AllowNull()][string]$Value)

    $clean = ConvertTo-CleanString -Value $Value
    return $clean -match "^(yes|no|true|false|1|0|y|n)$"
}

function Split-AccessTypeList {
    param([AllowNull()][string]$Value)

    $clean = ConvertTo-CleanString -Value $Value
    if ([string]::IsNullOrWhiteSpace($clean)) {
        return @()
    }

# Some exports pack more than one access type into one cell. Split the list so
# each access request can be planned cleanly.
    return $clean -split "[;,]" |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ } |
        Sort-Object -Unique
}

function Get-RequiredColumnErrors {
    param([Parameter(Mandatory)]$Row)

    $missing = foreach ($column in $RequiredColumns) {
        if (-not $Row.PSObject.Properties.Name.Contains($column)) {
            $column
        }
    }

    return $missing
}

function Test-ExternalAccessRow {
    param(
        [Parameter(Mandatory)]$Row,
        [Parameter(Mandatory)][int]$RowNumber
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $missingColumns = @(Get-RequiredColumnErrors -Row $Row)

# Validate before planning. Bad rows should be reported clearly instead of
# causing half-finished work.
    foreach ($column in $missingColumns) {
        $errors.Add("Missing required column: $column")
    }

    if ($missingColumns.Count -gt 0) {
        return $errors
    }

    $unexpectedColumns = @(
        $Row.PSObject.Properties.Name |
            Where-Object { $RequiredColumns -notcontains $_ -and $_ -match "^H\d+$" }
    )

    if ($unexpectedColumns.Count -gt 0) {
        $errors.Add("Row $RowNumber appears to have extra CSV values or shifted columns")
    }

    if ([string]::IsNullOrWhiteSpace($Row.ExternalPersonId)) {
        $errors.Add("Row $RowNumber has no ExternalPersonId")
    }

    if ([string]::IsNullOrWhiteSpace($Row.FirstName) -or [string]::IsNullOrWhiteSpace($Row.LastName)) {
        $errors.Add("Row $RowNumber is missing first or last name")
    }

    if (-not [string]::IsNullOrWhiteSpace($Row.Email) -and $Row.Email -notmatch "^[^@\s]+@[^@\s]+\.[^@\s]+$") {
        $errors.Add("Row $RowNumber has invalid Email: $($Row.Email)")
    }

    $accessTypes = @(Split-AccessTypeList -Value $Row.AccessType)
    if ($accessTypes.Count -eq 0) {
        $errors.Add("Row $RowNumber has no AccessType")
    }

    foreach ($accessType in $accessTypes) {
        if (-not $AccessTypeMap.ContainsKey($accessType)) {
            $errors.Add("Row $RowNumber has unknown AccessType '$accessType'")
        }
    }

    $startDate = ConvertTo-DateOrNull -Value $Row.RotationStartDate
    $endDate = ConvertTo-DateOrNull -Value $Row.RotationEndDate

# Start and end dates matter. Access should not live forever because the import
# file was messy.
    if ($null -eq $startDate) {
        $errors.Add("Row $RowNumber has invalid RotationStartDate: $($Row.RotationStartDate)")
    }

    if ($null -eq $endDate) {
        $errors.Add("Row $RowNumber has invalid RotationEndDate: $($Row.RotationEndDate)")
    }

    if ($null -ne $startDate -and $null -ne $endDate -and $endDate -lt $startDate) {
        $errors.Add("Row $RowNumber has RotationEndDate before RotationStartDate")
    }

    $status = ConvertTo-CleanString -Value $Row.Status
    if ($status -and $status -notin @("Active", "Inactive", "Pending")) {
        $errors.Add("Row $RowNumber has unknown Status '$status'")
    }

    if (-not (Test-BooleanText -Value $Row.LicenseRequired)) {
        $errors.Add("Row $RowNumber has unclear LicenseRequired value '$($Row.LicenseRequired)'")
    }

    return $errors
}

function Import-MockDirectory {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

# Fake directory lookup. This lets the demo show matching and re-enable logic
# without connecting to anything real.
    return @(Import-Csv -LiteralPath $Path)
}

function Find-MockDirectoryUser {
    param(
        [Parameter(Mandatory)]$DirectoryUsers,
        [Parameter(Mandatory)][string]$ExternalPersonId,
        [AllowNull()][string]$AccessId,
        [AllowNull()][string]$Email
    )

    $cleanExternalId = ConvertTo-CleanString -Value $ExternalPersonId
    $cleanAccessId = ConvertTo-CleanString -Value $AccessId
    $cleanEmail = ConvertTo-CleanString -Value $Email

# Match in the order an admin would usually trust the data: external ID first,
# then known access ID, then email as a fallback.
    $match = $DirectoryUsers | Where-Object {
        $_.ExternalPersonId -eq $cleanExternalId
    } | Select-Object -First 1

    if ($match) {
        return $match
    }

    if ($cleanAccessId) {
        $match = $DirectoryUsers | Where-Object {
            $_.SamAccountName -eq $cleanAccessId
        } | Select-Object -First 1

        if ($match) {
            return $match
        }
    }

    if ($cleanEmail) {
        return $DirectoryUsers | Where-Object {
            $_.Email -eq $cleanEmail
        } | Select-Object -First 1
    }
}

function New-TemporaryPassword {
    param([int]$Length = 16)

    $numbers = "23456789"
    $upper = "ABCDEFGHJKLMNPQRSTUVWXYZ"
    $lower = "abcdefghijkmnopqrstuvwxyz"
    $special = "!@#$%&*"
    $all = ($numbers + $upper + $lower + $special).ToCharArray()

# Placeholder password for new-account planning only. Do not treat this as a
# real password policy.
    $chars = @(
        $numbers[(Get-Random -Minimum 0 -Maximum $numbers.Length)]
        $upper[(Get-Random -Minimum 0 -Maximum $upper.Length)]
        $lower[(Get-Random -Minimum 0 -Maximum $lower.Length)]
        $special[(Get-Random -Minimum 0 -Maximum $special.Length)]
    )

    while ($chars.Count -lt $Length) {
        $chars += $all[(Get-Random -Minimum 0 -Maximum $all.Length)]
    }

    return -join ($chars | Sort-Object { Get-Random })
}

function ConvertTo-BaseSamAccountName {
    param(
        [Parameter(Mandatory)][string]$FirstName,
        [Parameter(Mandatory)][string]$LastName
    )

    $cleanFirst = ($FirstName -replace "[^a-zA-Z]", "").ToLowerInvariant()
    $cleanLast = ($LastName -replace "[^a-zA-Z]", "").ToLowerInvariant()

    if ([string]::IsNullOrWhiteSpace($cleanFirst) -or [string]::IsNullOrWhiteSpace($cleanLast)) {
        return "user"
    }

# SamAccountName still has old length limits in many environments, so keep the
# planned name short.
    $base = "{0}{1}" -f $cleanFirst.Substring(0, 1), $cleanLast
    if ($base.Length -gt 20) {
        $base = $base.Substring(0, 20)
    }

    return $base
}

function Get-UniqueSamAccountName {
    param(
        [Parameter(Mandatory)][string]$FirstName,
        [Parameter(Mandatory)][string]$LastName,
        [Parameter(Mandatory)]$DirectoryUsers,
        [Parameter(Mandatory)]$ReservedNames
    )

    $base = ConvertTo-BaseSamAccountName -FirstName $FirstName -LastName $LastName
    $candidate = $base
    $counter = 1

# Check both the fake directory and names already planned in this run. Catch the
# duplicate before provisioning would fail.
    while (
        ($DirectoryUsers | Where-Object { $_.SamAccountName -eq $candidate }) -or
        $ReservedNames.Contains($candidate)
    ) {
        $suffix = $counter.ToString()
        $maxBaseLength = 20 - $suffix.Length
        $candidate = "{0}{1}" -f $base.Substring(0, [Math]::Min($base.Length, $maxBaseLength)), $suffix
        $counter++
    }

    $ReservedNames.Add($candidate) | Out-Null
    return $candidate
}

function Get-UniqueDisplayName {
    param(
        [Parameter(Mandatory)][string]$FirstName,
        [Parameter(Mandatory)][string]$LastName,
        [Parameter(Mandatory)]$DirectoryUsers
    )

    $baseName = "$FirstName $LastName"
    $exists = $DirectoryUsers | Where-Object { $_.DisplayName -eq $baseName } | Select-Object -First 1

# If the display name already exists, label the planned account so the report is
# easier to read.
    if ($exists) {
        return "$baseName (Training)"
    }

    return $baseName
}

function New-AccessFlags {
    param([Parameter(Mandatory)][string[]]$AccessTypes)

    $flags = [ordered]@{
        NeedsDirectoryAccount = $false
        NeedsMailbox          = $false
        NeedsClinicalApp      = $false
        NeedsSharedDrive      = $false
        NeedsRemoteAccess     = $false
    }

# Flags make the final CSV easier to scan without reading the full action text.
    foreach ($accessType in $AccessTypes) {
        if ($AccessTypeMap.ContainsKey($accessType)) {
            $flagName = $AccessTypeMap[$accessType].Flag
            $flags[$flagName] = $true
        }
    }

    return [pscustomobject]$flags
}

function New-ReviewWarningList {
    param([Parameter(Mandatory)]$MergedUser)

    $warnings = New-Object System.Collections.Generic.List[string]

    if ([string]::IsNullOrWhiteSpace($MergedUser.TicketId)) {
        $warnings.Add("Missing ticket ID for service desk handoff")
    }

    if ($MergedUser.AccessTypes -contains "Email" -and [string]::IsNullOrWhiteSpace($MergedUser.Email)) {
        $warnings.Add("Email access requested but source email is blank")
    }

    if ($MergedUser.AccessTypes -contains "Network Login" -and [string]::IsNullOrWhiteSpace($MergedUser.AccessId)) {
        $warnings.Add("Network login requested without an access ID from the source export")
    }

    if ($null -eq $MergedUser.RotationStartDate -or $null -eq $MergedUser.RotationEndDate) {
        $warnings.Add("Rotation dates need manual review")
    }

    if ($MergedUser.SourceRowCount -gt 1) {
        $warnings.Add("Multiple source rows were merged for this person")
    }

    return @($warnings)
}

function Merge-ExternalAccessRows {
    param([Parameter(Mandatory)]$Rows)

    $merged = New-Object System.Collections.Generic.List[object]
    $groups = $Rows | Group-Object -Property ExternalPersonId

# The export may have several rows for one person. Merge them into one planned
# person with multiple access needs.
    foreach ($group in $groups) {
        $first = $group.Group | Select-Object -First 1
        $accessTypes = $group.Group |
            ForEach-Object { Split-AccessTypeList -Value $_.AccessType } |
            Sort-Object -Unique

        $accessId = ($group.Group |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_.AccessId) } |
            Select-Object -ExpandProperty AccessId -First 1)

        $accessPassword = ($group.Group |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_.AccessPassword) } |
            Select-Object -ExpandProperty AccessPassword -First 1)

        $comments = $group.Group |
            ForEach-Object { ConvertTo-CleanString -Value $_.Comments } |
            Where-Object { $_ } |
            Sort-Object -Unique

# Keep the earliest start and latest end date so the plan covers the full access
# window.
        $startDates = $group.Group | ForEach-Object { ConvertTo-DateOrNull -Value $_.RotationStartDate } | Where-Object { $_ }
        $endDates = $group.Group | ForEach-Object { ConvertTo-DateOrNull -Value $_.RotationEndDate } | Where-Object { $_ }

        $startDate = $startDates | Sort-Object | Select-Object -First 1
        $endDate = $endDates | Sort-Object -Descending | Select-Object -First 1

        $merged.Add([pscustomobject]@{
            ExternalPersonId   = $first.ExternalPersonId
            FirstName          = $first.FirstName
            LastName           = $first.LastName
            Email              = $first.Email
            Program            = $first.Program
            Service            = $first.Service
            TrainingLevel      = $first.TrainingLevel
            RotationStartDate  = $startDate
            RotationEndDate    = $endDate
            RotationLocation   = $first.RotationLocation
            AccessTypes        = @($accessTypes)
            AccessId           = $accessId
            AccessPassword     = $accessPassword
            ActivationDate     = ConvertTo-DateOrNull -Value $first.ActivationDate
            DeactivationDate   = ConvertTo-DateOrNull -Value $first.DeactivationDate
            Comments           = ($comments -join " | ")
            Status             = $first.Status
            LicenseRequired    = ConvertTo-BooleanText -Value $first.LicenseRequired
            TicketId           = $first.TicketId
            SourceRowCount     = $group.Count
        })
    }

    return $merged
}

function Resolve-TargetOu {
    param([AllowNull()][string]$Program)

    $cleanProgram = ConvertTo-CleanString -Value $Program
    if ($ProgramOuMap.ContainsKey($cleanProgram)) {
        return $ProgramOuMap[$cleanProgram]
    }

    return "OU=GeneralTraining,OU=Training,DC=example,DC=local"
}

function New-DirectoryActionText {
    param(
        [Parameter(Mandatory)][string]$AccountState,
        [Parameter(Mandatory)][string]$TargetOu
    )

    $actions = New-Object System.Collections.Generic.List[string]

    switch ($AccountState) {
        "ExistingDisabled" {
            $actions.Add("Re-enable directory account")
            $actions.Add("Update account expiration date")
            $actions.Add("Confirm UPN and display name")
        }
        "ExistingEnabled" {
            $actions.Add("Confirm existing directory account")
            $actions.Add("Update training attributes")
            $actions.Add("Confirm account expiration date")
        }
        default {
            $actions.Add("Create directory account")
            $actions.Add("Set initial password")
            $actions.Add("Move account to $TargetOu")
            $actions.Add("Set UPN and display name")
        }
    }

    return ($actions -join ";")
}

function New-MailboxActionText {
    param(
        [Parameter(Mandatory)]$PlanItem
    )

    if (-not $PlanItem.NeedsMailbox) {
        return "No mailbox action requested"
    }

    $actions = New-Object System.Collections.Generic.List[string]
    $actions.Add("Plan Exchange mailbox or remote mailbox enablement")
    $actions.Add("Confirm primary email address")
    $actions.Add("Confirm mail routing after account plan is approved")

    if ($PlanItem.AccountState -eq "New") {
        $actions.Add("Wait for directory account before mailbox step")
    }

    return ($actions -join ";")
}

function New-ServiceDeskActionText {
    param(
        [Parameter(Mandatory)]$PlanItem,
        [AllowEmptyCollection()][string[]]$Warnings = @()
    )

    $actions = New-Object System.Collections.Generic.List[string]
    $actions.Add("Prepare ServiceNow-style ticket update")
    $actions.Add("Include account, access, date, and group summary")

    if ($Warnings.Count -gt 0) {
        $actions.Add("Flag review notes before handoff")
    } else {
        $actions.Add("Ready for standard handoff")
    }

    return ($actions -join ";")
}

function New-GroupMembershipActionText {
    param([AllowNull()][string]$TargetGroups)

    if ([string]::IsNullOrWhiteSpace($TargetGroups)) {
        return "No group membership changes requested"
    }

    return "Add or confirm group membership: $TargetGroups"
}

function New-EmailNotificationActionText {
    param(
        [Parameter(Mandatory)]$PlanItem,
        [AllowEmptyCollection()][string[]]$Warnings = @()
    )

    $actions = New-Object System.Collections.Generic.List[string]
    $actions.Add("Prepare notification email for application/support teams")
    $actions.Add("Include learner identity, account, access types, rotation dates, and ticket reference")

    if ($PlanItem.NeedsMailbox) {
        $actions.Add("Include mailbox planning details")
    }

    if ($Warnings.Count -gt 0) {
        $actions.Add("Include review warnings before fulfillment")
    }

    return ($actions -join ";")
}

function New-ServiceNowTaskSummary {
    param([Parameter(Mandatory)]$PlanItem)

    return "Create or update onboarding task for $($PlanItem.DisplayName) covering account state '$($PlanItem.AccountState)', access '$($PlanItem.AccessTypes)', and ticket '$($PlanItem.TicketId)'"
}

function New-ExternalAccessPlanItem {
    param(
        [Parameter(Mandatory)]$MergedUser,
        [Parameter(Mandatory)]$DirectoryUsers,
        [Parameter(Mandatory)]$ReservedNames,
        [Parameter(Mandatory)][string]$Domain
    )

    $existing = Find-MockDirectoryUser -DirectoryUsers $DirectoryUsers `
        -ExternalPersonId $MergedUser.ExternalPersonId `
        -AccessId $MergedUser.AccessId `
        -Email $MergedUser.Email

# Core planning decision. The real script worked with account objects here; the
# demo writes the decision as data.
    $samAccountName = if ($existing) {
        $existing.SamAccountName
    } elseif (-not [string]::IsNullOrWhiteSpace($MergedUser.AccessId)) {
        $MergedUser.AccessId
    } else {
        Get-UniqueSamAccountName -FirstName $MergedUser.FirstName -LastName $MergedUser.LastName -DirectoryUsers $DirectoryUsers -ReservedNames $ReservedNames
    }

    $displayName = if ($existing) {
        $existing.DisplayName
    } else {
        Get-UniqueDisplayName -FirstName $MergedUser.FirstName -LastName $MergedUser.LastName -DirectoryUsers $DirectoryUsers
    }

    $flags = New-AccessFlags -AccessTypes $MergedUser.AccessTypes
    $targetGroups = foreach ($accessType in $MergedUser.AccessTypes) {
        if ($AccessTypeMap.ContainsKey($accessType)) {
            $AccessTypeMap[$accessType].Group
        }
    }

    $plannedActions = New-Object System.Collections.Generic.List[string]
    $accountState = "New"
    $matchedBy = "No existing match"

# Existing disabled accounts need a different plan than brand-new people. This
# is what makes the workflow more than CSV-to-user.
    if ($existing) {
        $accountState = if (ConvertTo-BooleanText -Value $existing.Enabled) { "ExistingEnabled" } else { "ExistingDisabled" }
        $matchedBy = "Matched mock directory by ExternalPersonId, AccessId, or Email"

        if ($accountState -eq "ExistingDisabled") {
            $plannedActions.Add("Re-enable existing directory account")
        } else {
            $plannedActions.Add("Confirm existing directory account")
        }

        $plannedActions.Add("Update account dates and training attributes")
    } else {
        $plannedActions.Add("Create new directory account")
        $plannedActions.Add("Set generated temporary password")
    }

    foreach ($accessType in $MergedUser.AccessTypes) {
        $plannedActions.Add($AccessTypeMap[$accessType].Action)
    }

# Keep license handling generic here. The point is that source data drives the
# access bundles that need planning.
    if ($MergedUser.LicenseRequired) {
        $plannedActions.Add("Add training license group")
    }

    $plannedActions.Add("Prepare ServiceNow-style task handoff")
    $plannedActions.Add("Prepare notification email draft")

    $targetOu = Resolve-TargetOu -Program $MergedUser.Program
    $warnings = @(New-ReviewWarningList -MergedUser $MergedUser)

# No real password is printed or set. New accounts only show that a temporary
# password would be planned.
    $temporaryPassword = if ($MergedUser.AccessPassword) {
        "Provided by source export - not shown in public report"
    } elseif ($existing) {
        "Not changed for existing account"
    } else {
        "Generated at runtime - not shown in public report"
    }

    $planItem = [pscustomobject]@{
        ExternalPersonId       = $MergedUser.ExternalPersonId
        TicketId                = $MergedUser.TicketId
        FirstName               = $MergedUser.FirstName
        LastName                = $MergedUser.LastName
        DisplayName             = $displayName
        SamAccountName          = $samAccountName
        UserPrincipalName       = "$samAccountName@$Domain"
        Email                   = $MergedUser.Email
        Program                 = $MergedUser.Program
        Service                 = $MergedUser.Service
        TrainingLevel           = $MergedUser.TrainingLevel
        RotationLocation        = $MergedUser.RotationLocation
        RotationStartDate       = Format-DateValue -Date $MergedUser.RotationStartDate
        RotationEndDate         = Format-DateValue -Date $MergedUser.RotationEndDate
        ActivationDate          = Format-DateValue -Date $MergedUser.ActivationDate
        DeactivationDate        = Format-DateValue -Date $MergedUser.DeactivationDate
        AccountState            = $accountState
        MatchedBy               = $matchedBy
        TargetOu                = $targetOu
        AccessTypes             = ($MergedUser.AccessTypes -join ";")
        TargetGroups            = (($targetGroups | Sort-Object -Unique) -join ";")
        NeedsDirectoryAccount   = $flags.NeedsDirectoryAccount
        NeedsMailbox            = $flags.NeedsMailbox
        NeedsClinicalApp        = $flags.NeedsClinicalApp
        NeedsSharedDrive        = $flags.NeedsSharedDrive
        NeedsRemoteAccess       = $flags.NeedsRemoteAccess
        LicenseRequired         = $MergedUser.LicenseRequired
        TemporaryPasswordStatus = $temporaryPassword
        SourceRowCount          = $MergedUser.SourceRowCount
        Comments                = $MergedUser.Comments
        ReviewWarnings          = ($warnings -join ";")
        PlannedActions          = ($plannedActions | Sort-Object -Unique) -join ";"
    }

    # Split the plan into directory, mailbox, service desk, group, and
    # notification lanes without touching real systems.
    $planItem | Add-Member -NotePropertyName DirectoryActions -NotePropertyValue (New-DirectoryActionText -AccountState $planItem.AccountState -TargetOu $planItem.TargetOu)
    $planItem | Add-Member -NotePropertyName MailboxActions -NotePropertyValue (New-MailboxActionText -PlanItem $planItem)
    $planItem | Add-Member -NotePropertyName ServiceDeskActions -NotePropertyValue (New-ServiceDeskActionText -PlanItem $planItem -Warnings $warnings)
    $planItem | Add-Member -NotePropertyName GroupMembershipActions -NotePropertyValue (New-GroupMembershipActionText -TargetGroups $planItem.TargetGroups)
    $planItem | Add-Member -NotePropertyName EmailNotificationActions -NotePropertyValue (New-EmailNotificationActionText -PlanItem $planItem -Warnings $warnings)
    $planItem | Add-Member -NotePropertyName ServiceNowTaskSummary -NotePropertyValue (New-ServiceNowTaskSummary -PlanItem $planItem)

    return $planItem
}

function New-NotificationDraft {
    param(
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][string]$Tenant
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Notification Drafts")
    $lines.Add("")
    $lines.Add("These are fake draft notes. The script does not send email or create tickets.")
    $lines.Add("")

# Write Markdown drafts instead of sending anything. This shows the handoff step
# without exposing recipients, SMTP settings, or tickets.
    foreach ($item in $Plan) {
        $lines.Add("## $($item.DisplayName)")
        $lines.Add("")
        $lines.Add("Subject: External access onboarding for $($item.DisplayName) [$($item.ExternalPersonId)]")
        $lines.Add("")
        $lines.Add("Tenant: $Tenant")
        $lines.Add("Ticket: $($item.TicketId)")
        $lines.Add("Account: $($item.SamAccountName)")
        $lines.Add("Program: $($item.Program)")
        $lines.Add("Service: $($item.Service)")
        $lines.Add("Training level: $($item.TrainingLevel)")
        $lines.Add("Rotation location: $($item.RotationLocation)")
        $lines.Add("Access: $($item.AccessTypes)")
        $lines.Add("Dates: $($item.RotationStartDate) to $($item.RotationEndDate)")
        $lines.Add("Groups: $($item.TargetGroups)")
        $lines.Add("Directory plan: $($item.DirectoryActions)")
        $lines.Add("Mailbox plan: $($item.MailboxActions)")
        $lines.Add("Service desk plan: $($item.ServiceDeskActions)")
        $lines.Add("Review warnings: $($item.ReviewWarnings)")
        $lines.Add("Planned actions: $($item.PlannedActions)")
        $lines.Add("")
    }

    return $lines
}

function Export-WorkflowReports {
    param(
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][string]$Tenant
    )

    $planCsv = Get-UniqueFileName -Directory $Directory -BaseName "external-access-plan" -Extension ".csv"
    $planJson = Get-UniqueFileName -Directory $Directory -BaseName "external-access-plan" -Extension ".json"
    $accessSummaryCsv = Get-UniqueFileName -Directory $Directory -BaseName "access-summary" -Extension ".csv"
    $directoryPlanCsv = Get-UniqueFileName -Directory $Directory -BaseName "directory-action-plan" -Extension ".csv"
    $mailboxPlanCsv = Get-UniqueFileName -Directory $Directory -BaseName "exchange-mailbox-plan" -Extension ".csv"
    $serviceDeskPlanCsv = Get-UniqueFileName -Directory $Directory -BaseName "service-desk-handoff-plan" -Extension ".csv"
    $notificationDraft = Get-UniqueFileName -Directory $Directory -BaseName "notification-drafts" -Extension ".md"

# Write several report shapes because different readers need different views:
# full plan, JSON, handoff reports, summary CSV, and draft notes.
    $Plan | Export-Csv -NoTypeInformation -LiteralPath $planCsv
    $Plan | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $planJson -Encoding UTF8

    $Plan |
        Select-Object ExternalPersonId, DisplayName, SamAccountName, AccountState, AccessTypes, TargetGroups, GroupMembershipActions, RotationStartDate, RotationEndDate, PlannedActions, ReviewWarnings |
        Export-Csv -NoTypeInformation -LiteralPath $accessSummaryCsv

    $Plan |
        Select-Object ExternalPersonId, DisplayName, SamAccountName, UserPrincipalName, AccountState, TargetOu, DirectoryActions, GroupMembershipActions, ActivationDate, DeactivationDate, ReviewWarnings |
        Export-Csv -NoTypeInformation -LiteralPath $directoryPlanCsv

    $Plan |
        Select-Object ExternalPersonId, DisplayName, SamAccountName, Email, NeedsMailbox, MailboxActions, EmailNotificationActions, ReviewWarnings |
        Export-Csv -NoTypeInformation -LiteralPath $mailboxPlanCsv

    $Plan |
        Select-Object TicketId, ExternalPersonId, DisplayName, AccessTypes, ServiceNowTaskSummary, ServiceDeskActions, EmailNotificationActions, ReviewWarnings, Comments |
        Export-Csv -NoTypeInformation -LiteralPath $serviceDeskPlanCsv

    New-NotificationDraft -Plan $Plan -Tenant $Tenant |
        Set-Content -LiteralPath $notificationDraft -Encoding UTF8

    return [pscustomobject]@{
        PlanCsv           = $planCsv
        PlanJson          = $planJson
        AccessSummaryCsv  = $accessSummaryCsv
        DirectoryPlanCsv  = $directoryPlanCsv
        MailboxPlanCsv    = $mailboxPlanCsv
        ServiceDeskPlanCsv = $serviceDeskPlanCsv
        NotificationDraft = $notificationDraft
    }
}

function Invoke-SimulatedApply {
    param(
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][string]$Directory
    )

    $logPath = Get-UniqueFileName -Directory $Directory -BaseName "simulated-apply" -Extension ".log"

# A production script might create accounts, add groups, update dates, or send
# notifications here. The demo only logs what it would do.
    foreach ($item in $Plan) {
        Write-DemoLog -Path $logPath -Message "Would process $($item.SamAccountName) for external ID $($item.ExternalPersonId)"
        Write-DemoLog -Path $logPath -Message "Would target OU: $($item.TargetOu)"
        Write-DemoLog -Path $logPath -Message "Would apply groups: $($item.TargetGroups)"
        Write-DemoLog -Path $logPath -Message "Would perform actions: $($item.PlannedActions)"
    }

    return $logPath
}

$OutputDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory)
New-SafeDirectory -Path $OutputDirectory

$runLog = Get-UniqueFileName -Directory $OutputDirectory -BaseName "run-log" -Extension ".txt"
Write-DemoLog -Path $runLog -Message "Starting external access onboarding demo in $Mode mode"

# Load the source export and the fake directory snapshot separately so the
# current account state is easy to reason about.
$rows = @(Import-Csv -LiteralPath $CsvPath)
$directoryUsers = @(Import-MockDirectory -Path $MockDirectoryPath)
$validationErrors = New-Object System.Collections.Generic.List[object]
$validRows = New-Object System.Collections.Generic.List[object]

for ($index = 0; $index -lt $rows.Count; $index++) {
    $rowNumber = $index + 2
    $row = $rows[$index]
    $rowErrors = @(Test-ExternalAccessRow -Row $row -RowNumber $rowNumber)

# Collect bad rows and keep processing the good ones. One bad record should not
# ruin the whole run.
    if ($rowErrors.Count -gt 0) {
        foreach ($errorMessage in $rowErrors) {
            $validationErrors.Add([pscustomobject]@{
                RowNumber        = $rowNumber
                ExternalPersonId = $row.ExternalPersonId
                Error            = $errorMessage
            })
        }
        continue
    }

    $validRows.Add($row)
}

if ($validationErrors.Count -gt 0) {
    $errorPath = Get-UniqueFileName -Directory $OutputDirectory -BaseName "validation-errors" -Extension ".csv"
    $validationErrors | Export-Csv -NoTypeInformation -LiteralPath $errorPath
    Write-Warning "Validation found $($validationErrors.Count) issue(s). See $errorPath"
    Write-DemoLog -Path $runLog -Level "WARN" -Message "Validation found $($validationErrors.Count) issue(s)"
}

if ($Mode -eq "ValidateOnly") {
    Write-Output "Validation complete. Valid rows: $($validRows.Count). Errors: $($validationErrors.Count)."
    Write-Output "Run log written to $runLog"
    return
}

# After validation, merge duplicate source rows and turn each person into a
# reviewable access plan.
$mergedUsers = @(Merge-ExternalAccessRows -Rows $validRows)
$reservedNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$plan = foreach ($mergedUser in $mergedUsers) {
    New-ExternalAccessPlanItem -MergedUser $mergedUser -DirectoryUsers $directoryUsers -ReservedNames $reservedNames -Domain $DomainName
}

$reports = Export-WorkflowReports -Plan $plan -Directory $OutputDirectory -Tenant $TenantName

# Keep console output short. The detail belongs in the generated reports and
# logs.
Write-Output "Plan written to $($reports.PlanCsv)"
Write-Output "JSON written to $($reports.PlanJson)"
Write-Output "Access summary written to $($reports.AccessSummaryCsv)"
Write-Output "Directory action plan written to $($reports.DirectoryPlanCsv)"
Write-Output "Exchange/mailbox plan written to $($reports.MailboxPlanCsv)"
Write-Output "Service desk handoff plan written to $($reports.ServiceDeskPlanCsv)"
Write-Output "Notification drafts written to $($reports.NotificationDraft)"
Write-Output "Run log written to $runLog"

if ($Mode -eq "SimulateApply") {
    if ($PSCmdlet.ShouldProcess("external access plan", "simulate account, access, and notification actions")) {
        $applyLog = Invoke-SimulatedApply -Plan $plan -Directory $OutputDirectory
        Write-Output "Simulation log written to $applyLog"
    }
}
