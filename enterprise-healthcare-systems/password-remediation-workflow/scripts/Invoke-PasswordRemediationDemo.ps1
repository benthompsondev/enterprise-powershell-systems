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
    [string]$StateDirectory,

    [Parameter()]
    [string]$ArchiveDirectory,

    [Parameter()]
    [ValidateSet("ValidateOnly", "PlanOnly", "SimulateApply")]
    [string]$Mode = "PlanOnly",

    [Parameter()]
    [int]$TotalPasses = 3,

    [Parameter()]
    [int]$MinimumDaysBetweenLivePasses = 6,

    [Parameter()]
    [switch]$ForceRun,

    [Parameter()]
    [switch]$SimulateFinalPass
)

$ErrorActionPreference = "Stop"

$RequiredColumns = @(
    "DiscoveryDate",
    "EmployeeId",
    "SamAccountName",
    "UserPrincipalName",
    "DisplayName",
    "PasswordLastSet",
    "AccountEnabled",
    "AccountType",
    "Department",
    "ManagerEmail",
    "ExemptionReason",
    "LastAction",
    "LastActionDate"
)

function Resolve-DemoPath {
    param([Parameter(Mandatory)][string]$Path)
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

function New-SafeDirectory {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-DemoLog {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")][string]$Level = "INFO"
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -LiteralPath $Path -Value $line -Encoding UTF8
}

function Get-CsvPropertyValue {
    param(
        [Parameter(Mandatory)]$Row,
        [Parameter(Mandatory)][string[]]$Names
    )

    foreach ($name in $Names) {
        if ($Row.PSObject.Properties.Name -contains $name) {
            return [string]$Row.$name
        }
    }

    return ""
}

function ConvertTo-BooleanOrNull {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $clean = $Value.Trim().ToLowerInvariant()
    if ($clean -in @("true", "yes", "y", "1", "enabled", "no-disabled-flag")) { return $true }
    if ($clean -in @("false", "no", "n", "0", "disabled")) { return $false }
    return $null
}

function ConvertTo-DateOrNull {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $formats = @("yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd", "M/d/yyyy", "MM/dd/yyyy", "dd-MMM-yy", "dd-MMM-yyyy")
    foreach ($format in $formats) {
        try {
            return [datetime]::ParseExact($Value.Trim(), $format, [Globalization.CultureInfo]::InvariantCulture)
        } catch {
            # Try the next known export format.
        }
    }

    try {
        return [datetime]::Parse($Value.Trim(), [Globalization.CultureInfo]::InvariantCulture)
    } catch {
        return $null
    }
}

function Get-FileHashText {
    param([Parameter(Mandatory)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Test-FileReady {
    param([Parameter(Mandatory)][string]$Path)

    try {
        $stream = [System.IO.File]::Open($Path, "Open", "Read", "None")
        $stream.Close()
        return $true
    } catch {
        return $false
    }
}

function Test-RequiredColumns {
    param([Parameter(Mandatory)]$Row)

    foreach ($column in $RequiredColumns) {
        if ($Row.PSObject.Properties.Name -notcontains $column) {
            $column
        }
    }
}

function Test-PasswordReviewRow {
    param(
        [Parameter(Mandatory)]$Row,
        [Parameter(Mandatory)][int]$RowNumber
    )

    $errors = @()
    $missing = @(Test-RequiredColumns -Row $Row)
    foreach ($column in $missing) {
        $errors += [pscustomobject]@{
            RowNumber = $RowNumber
            Field     = $column
            Issue     = "Missing required column"
        }
    }

    if ($missing.Count -gt 0) {
        return $errors
    }

    foreach ($field in @("EmployeeId", "SamAccountName", "UserPrincipalName", "DisplayName")) {
        if ([string]::IsNullOrWhiteSpace((Get-CsvPropertyValue -Row $Row -Names $field))) {
            $errors += [pscustomobject]@{
                RowNumber = $RowNumber
                Field     = $field
                Issue     = "Required value is blank"
            }
        }
    }

    foreach ($field in @("UserPrincipalName", "ManagerEmail")) {
        $value = Get-CsvPropertyValue -Row $Row -Names $field
        if ($value -and $value -notmatch "^[^@\s]+@[^@\s]+\.[^@\s]+$") {
            $errors += [pscustomobject]@{
                RowNumber = $RowNumber
                Field     = $field
                Issue     = "$field is not email-shaped"
            }
        }
    }

    $enabled = ConvertTo-BooleanOrNull -Value (Get-CsvPropertyValue -Row $Row -Names "AccountEnabled")
    if ($null -eq $enabled) {
        $errors += [pscustomobject]@{
            RowNumber = $RowNumber
            Field     = "AccountEnabled"
            Issue     = "AccountEnabled must be true/false style text"
        }
    }

    return $errors
}

function Import-PasswordReviewCsv {
    param([Parameter(Mandatory)][string]$Path)
    return @(Import-Csv -LiteralPath $Path)
}

function Import-MockDirectory {
    param([Parameter(Mandatory)][string]$Path)
    return @(Import-Csv -LiteralPath $Path)
}

function Resolve-MockDirectoryUser {
    param(
        [Parameter(Mandatory)]$Row,
        [Parameter(Mandatory)][array]$DirectoryUsers
    )

    $employeeId = (Get-CsvPropertyValue -Row $Row -Names "EmployeeId").Trim()
    $sam = (Get-CsvPropertyValue -Row $Row -Names "SamAccountName", "Username", "User ID", "Login", "Account", "Secondary Name").Trim()
    $upn = (Get-CsvPropertyValue -Row $Row -Names "UserPrincipalName", "UPN", "Email", "PrimarySMTPAddress").Trim()

    if ($sam -match "\\") {
        $sam = ($sam -split "\\")[-1]
    }

    return $DirectoryUsers | Where-Object {
        $_.EmployeeId -eq $employeeId -or
        $_.SamAccountName -eq $sam -or
        $_.UserPrincipalName -eq $upn
    } | Select-Object -First 1
}

function Get-UserCategory {
    param(
        [Parameter(Mandatory)]$Row,
        $DirectoryUser
    )

    $csvEnabled = ConvertTo-BooleanOrNull -Value (Get-CsvPropertyValue -Row $Row -Names "AccountEnabled")
    $directoryEnabled = if ($DirectoryUser) { ConvertTo-BooleanOrNull -Value $DirectoryUser.Enabled } else { $null }
    $accountType = (Get-CsvPropertyValue -Row $Row -Names "AccountType", "User Classification").Trim()
    $department = (Get-CsvPropertyValue -Row $Row -Names "Department", "Org. Unit").Trim()
    $exemption = (Get-CsvPropertyValue -Row $Row -Names "ExemptionReason", "Notes").Trim()

    if (-not $DirectoryUser) { return "MissingDirectoryMatch" }
    if ($csvEnabled -eq $false -or $directoryEnabled -eq $false) { return "DisabledAccount" }
    if ($accountType -match "(?i)service|shared|breakglass" -or $department -match "(?i)service|shared|testing|mdm|terminated|stale|inactive") {
        return "ServiceOrSpecialAccount"
    }
    if ($exemption) { return "ExemptAccount" }

    return "StandardAccount"
}

function Test-DirectoryUserCompliant {
    param(
        $DirectoryUser,
        [Parameter(Mandatory)][datetime]$ComplianceCutoff
    )

    if (-not $DirectoryUser) {
        return $false
    }

    $passwordLastSet = ConvertTo-DateOrNull -Value $DirectoryUser.PasswordLastSet
    if (-not $passwordLastSet) {
        return $false
    }

    return $passwordLastSet -ge $ComplianceCutoff
}

function Get-CycleMode {
    param([Parameter(Mandatory)][int]$PassNumber)

    switch ($PassNumber) {
        1 { "Reminder1" }
        2 { "FinalReminder" }
        default { "ForceReset" }
    }
}

function Get-OrCreateCycleState {
    param(
        [Parameter(Mandatory)][string]$StatePath,
        [Parameter(Mandatory)][string]$CsvFullName,
        [Parameter(Mandatory)][string]$CsvHash,
        [Parameter(Mandatory)][int]$TotalPasses
    )

    if (Test-Path -LiteralPath $StatePath) {
        $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
        if ($state.CsvHash -eq $CsvHash) {
            return $state
        }
    }

    # The real system locks the cutoff when the cycle starts. The public demo
    # uses the CSV timestamp if available, otherwise the current time.
    $cutoff = (Get-Item -LiteralPath $CsvFullName).LastWriteTime

    return [pscustomobject]@{
        CsvName           = [System.IO.Path]::GetFileName($CsvFullName)
        CsvFullName       = [System.IO.Path]::GetFileName($CsvFullName)
        CsvHash           = $CsvHash
        CycleStarted      = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        ComplianceCutoff  = $cutoff.ToString("yyyy-MM-dd HH:mm:ss")
        RunsCompleted     = 0
        LastRunDate       = $null
        Archived          = $false
        ArchivedPath      = $null
        StateArchivedPath = $null
        TotalPasses       = $TotalPasses
    }
}

function Save-CycleState {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$Path
    )

    $State | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Test-RunTooSoon {
    param(
        $State,
        [Parameter(Mandatory)][int]$MinimumDays
    )

    if (-not $State.LastRunDate) {
        return $false
    }

    $lastRun = ConvertTo-DateOrNull -Value $State.LastRunDate
    if (-not $lastRun) {
        return $false
    }

    return ((Get-Date) - $lastRun).TotalDays -lt $MinimumDays
}

function New-ReviewWarningList {
    param(
        [Parameter(Mandatory)]$Row,
        [string]$Category,
        [string]$CycleMode,
        $DirectoryUser,
        [bool]$Compliant
    )

    $warnings = @()
    if ($Category -eq "MissingDirectoryMatch") {
        $warnings += "No mock directory match found"
    }
    if ($Category -eq "DisabledAccount") {
        $warnings += "Account disabled in source or mock directory"
    }
    if ($Category -eq "ServiceOrSpecialAccount") {
        $warnings += "Service/shared/special account category excluded"
    }
    if ($Category -eq "ExemptAccount") {
        $warnings += "Exemption reason present in source export"
    }
    if (-not $DirectoryUser -or [string]::IsNullOrWhiteSpace($DirectoryUser.ManagerEmail)) {
        $warnings += "Manager email missing from mock directory"
    }
    if ($CycleMode -eq "ForceReset" -and $Category -eq "StandardAccount" -and -not $Compliant) {
        $warnings += "Final pass would require password change at next logon"
    }

    return $warnings
}

function New-RemediationPlan {
    param(
        [Parameter(Mandatory)][array]$Rows,
        [Parameter(Mandatory)][array]$DirectoryUsers,
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][int]$PassNumber
    )

    $cycleMode = Get-CycleMode -PassNumber $PassNumber
    $cutoff = ConvertTo-DateOrNull -Value $State.ComplianceCutoff
    $plan = @()

    foreach ($row in $Rows) {
        $directoryUser = Resolve-MockDirectoryUser -Row $row -DirectoryUsers $DirectoryUsers
        $category = Get-UserCategory -Row $row -DirectoryUser $directoryUser
        $compliant = Test-DirectoryUserCompliant -DirectoryUser $directoryUser -ComplianceCutoff $cutoff

        $email = if ($directoryUser -and $directoryUser.UserPrincipalName) { $directoryUser.UserPrincipalName } else { $row.UserPrincipalName }
        $passwordLastSet = if ($directoryUser) { $directoryUser.PasswordLastSet } else { $row.PasswordLastSet }

        $stage = "Skip"
        $plannedActions = @("Record reason for review")
        if ($category -eq "StandardAccount" -and $compliant) {
            $stage = "Compliant"
            $plannedActions = @("No action needed"; "Stop processing this user for the cycle")
        } elseif ($category -eq "StandardAccount") {
            switch ($cycleMode) {
                "Reminder1" {
                    $stage = "Reminder1Planned"
                    $plannedActions = @("Prepare first reminder email"; "Record reminder pass")
                }
                "FinalReminder" {
                    $stage = "FinalReminderPlanned"
                    $plannedActions = @("Prepare final reminder email"; "Record final reminder pass")
                }
                default {
                    $stage = "ForceResetPlanned"
                    $plannedActions = @("Plan ChangePasswordAtNextLogon"; "Prepare final reset notice"; "Record final remediation pass")
                }
            }
        }

        $warnings = @(New-ReviewWarningList -Row $row -Category $category -CycleMode $cycleMode -DirectoryUser $directoryUser -Compliant $compliant)

        $plan += [pscustomobject]@{
            EmployeeId         = $row.EmployeeId
            SamAccountName     = $row.SamAccountName
            UserPrincipalName  = $email
            DisplayName        = $row.DisplayName
            Department         = $row.Department
            Category           = $category
            PasswordLastSet    = $passwordLastSet
            ComplianceCutoff   = $State.ComplianceCutoff
            Compliant          = $compliant
            PassNumber         = $PassNumber
            TotalPasses        = $State.TotalPasses
            CycleMode          = $cycleMode
            RemediationStage   = $stage
            ManagerEmail       = if ($directoryUser) { $directoryUser.ManagerEmail } else { $row.ManagerEmail }
            PlannedActions     = ($plannedActions -join ";")
            ReviewWarnings     = ($warnings -join ";")
        }
    }

    return $plan
}

function New-NotificationDrafts {
    param([Parameter(Mandatory)][array]$Plan)

    $lines = @("# Notification Drafts", "")
    $lines += "These are fake drafts. The demo does not send email."
    $lines += ""

    foreach ($item in ($Plan | Where-Object { $_.RemediationStage -in @("Reminder1Planned", "FinalReminderPlanned", "ForceResetPlanned") })) {
        $subject = switch ($item.CycleMode) {
            "Reminder1" { "Password Security" }
            "FinalReminder" { "Password Security - Final Reminder" }
            default { "Password Reset Required at Next Login" }
        }

        $lines += "## $($item.DisplayName)"
        $lines += ""
        $lines += "Subject: $subject"
        $lines += ""
        $lines += "- Account: $($item.SamAccountName)"
        $lines += "- Pass: $($item.PassNumber) of $($item.TotalPasses)"
        $lines += "- Compliance cutoff: $($item.ComplianceCutoff)"
        $lines += "- Manager: $($item.ManagerEmail)"
        $lines += "- Planned actions: $($item.PlannedActions)"
        if ($item.ReviewWarnings) {
            $lines += "- Review warnings: $($item.ReviewWarnings)"
        }
        $lines += ""
    }

    return $lines -join [Environment]::NewLine
}

function New-RemediationSummary {
    param([Parameter(Mandatory)][array]$Plan)

    return $Plan |
        Group-Object CycleMode, RemediationStage |
        Sort-Object Name |
        ForEach-Object {
            $parts = $_.Name -split ", "
            [pscustomobject]@{
                CycleMode        = $parts[0]
                RemediationStage = $parts[1]
                Count            = $_.Count
            }
        }
}

function Write-PlanOutputs {
    param(
        [Parameter(Mandatory)][array]$Plan,
        [Parameter(Mandatory)][string]$OutputDirectory,
        [Parameter(Mandatory)][string]$LogPath
    )

    New-SafeDirectory -Path $OutputDirectory

    $planCsv = Join-Path $OutputDirectory "password-remediation-plan.csv"
    $planJson = Join-Path $OutputDirectory "password-remediation-plan.json"
    $summaryCsv = Join-Path $OutputDirectory "remediation-summary.csv"
    $snapshotCsv = Join-Path $OutputDirectory ("filtered-snapshot-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    $draftsPath = Join-Path $OutputDirectory "notification-drafts.md"

    $Plan | Export-Csv -LiteralPath $planCsv -NoTypeInformation
    $Plan | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $planJson -Encoding UTF8
    New-RemediationSummary -Plan $Plan | Export-Csv -LiteralPath $summaryCsv -NoTypeInformation
    $Plan | Export-Csv -LiteralPath $snapshotCsv -NoTypeInformation
    New-NotificationDrafts -Plan $Plan | Set-Content -LiteralPath $draftsPath -Encoding UTF8

    Write-DemoLog -Path $LogPath -Message "Plan written to $(Split-Path -Leaf $planCsv)"
    Write-DemoLog -Path $LogPath -Message "Summary written to $(Split-Path -Leaf $summaryCsv)"
    Write-DemoLog -Path $LogPath -Message "Snapshot written to $(Split-Path -Leaf $snapshotCsv)"
    Write-DemoLog -Path $LogPath -Message "Notification drafts written to $(Split-Path -Leaf $draftsPath)"
}

function Write-SimulatedApplyLog {
    param(
        [Parameter(Mandatory)][array]$Plan,
        [Parameter(Mandatory)][string]$OutputDirectory
    )

    $path = Join-Path $OutputDirectory "simulated-apply.log"
    $lines = @()
    foreach ($item in $Plan) {
        $lines += "{0} [INFO] Would process {1}: {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $item.SamAccountName, $item.PlannedActions
    }

    $lines | Set-Content -LiteralPath $path -Encoding UTF8
    return $path
}

function Archive-DemoCycle {
    param(
        [Parameter(Mandatory)][string]$CsvPath,
        [Parameter(Mandatory)][string]$StatePath,
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$ArchiveDirectory
    )

    $archiveMonth = Get-Date -Format "yyyy-MM"
    $targetFolder = Join-Path $ArchiveDirectory $archiveMonth
    New-SafeDirectory -Path $targetFolder

    $csvTarget = Join-Path $targetFolder ([System.IO.Path]::GetFileName($CsvPath))
    $stateTarget = Join-Path $targetFolder "cycle_state.json"

    $State.Archived = $true
    $State.ArchivedPath = "archive/$archiveMonth/$([System.IO.Path]::GetFileName($csvTarget))"
    $State.StateArchivedPath = "archive/$archiveMonth/$([System.IO.Path]::GetFileName($stateTarget))"

    Copy-Item -LiteralPath $CsvPath -Destination $csvTarget -Force
    $State | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $stateTarget -Encoding UTF8
}

$OutputDirectory = Resolve-DemoPath -Path $OutputDirectory
if (-not $StateDirectory) { $StateDirectory = Join-Path $OutputDirectory "state" }
if (-not $ArchiveDirectory) { $ArchiveDirectory = Join-Path $OutputDirectory "archive" }
$StateDirectory = Resolve-DemoPath -Path $StateDirectory
$ArchiveDirectory = Resolve-DemoPath -Path $ArchiveDirectory
$CsvPath = Resolve-DemoPath -Path $CsvPath
$MockDirectoryPath = Resolve-DemoPath -Path $MockDirectoryPath

New-SafeDirectory -Path $OutputDirectory
New-SafeDirectory -Path $StateDirectory

$logPath = Join-Path $OutputDirectory "audit-log.txt"
Set-Content -LiteralPath $logPath -Value ("{0} [INFO] Password remediation demo started in {1} mode" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Mode) -Encoding UTF8
Write-DemoLog -Path $logPath -Message "Test/simulation only. No email, AD, SMTP, file share, or credential access occurs."

if (-not (Test-FileReady -Path $CsvPath)) {
    Write-DemoLog -Path $logPath -Level "ERROR" -Message "CSV was not ready to read."
    throw "CSV was not ready to read."
}

$csvHash = Get-FileHashText -Path $CsvPath
$statePath = Join-Path $StateDirectory "cycle_state.json"
$state = Get-OrCreateCycleState -StatePath $statePath -CsvFullName $CsvPath -CsvHash $csvHash -TotalPasses $TotalPasses
Save-CycleState -State $state -Path $statePath

$rows = @(Import-PasswordReviewCsv -Path $CsvPath)
$directoryUsers = @(Import-MockDirectory -Path $MockDirectoryPath)

$validationErrors = @()
for ($i = 0; $i -lt $rows.Count; $i++) {
    $validationErrors += @(Test-PasswordReviewRow -Row $rows[$i] -RowNumber ($i + 2))
}

if ($validationErrors.Count -gt 0) {
    $validationPath = Join-Path $OutputDirectory "validation-errors.csv"
    $validationErrors | Export-Csv -LiteralPath $validationPath -NoTypeInformation
    Write-DemoLog -Path $logPath -Level "ERROR" -Message "Validation failed. See $validationPath"
    throw "Validation failed with $($validationErrors.Count) issue(s)."
}

Write-DemoLog -Path $logPath -Message "Validated $($rows.Count) source row(s)."

if ([int]$state.RunsCompleted -eq 0) {
    $exportCutoff = ConvertTo-DateOrNull -Value (Get-CsvPropertyValue -Row $rows[0] -Names "DiscoveryDate")
    if ($exportCutoff) {
        $state.ComplianceCutoff = $exportCutoff.ToString("yyyy-MM-dd HH:mm:ss")
        Save-CycleState -State $state -Path $statePath
        Write-DemoLog -Path $logPath -Message "Compliance cutoff locked from source export: $($state.ComplianceCutoff)"
    }
}

Write-DemoLog -Path $logPath -Message "CSV hash: $csvHash"
Write-DemoLog -Path $logPath -Message "State file: cycle_state.json"

if ($Mode -eq "ValidateOnly") {
    Write-Output "Validation passed."
    return
}

if ($Mode -eq "SimulateApply" -and -not $ForceRun -and (Test-RunTooSoon -State $state -MinimumDays $MinimumDaysBetweenLivePasses)) {
    Write-DemoLog -Path $logPath -Level "WARN" -Message "Duplicate-run guard blocked this pass. Use -ForceRun for controlled testing."
    throw "Duplicate-run guard blocked this pass. Use -ForceRun for controlled testing."
}

$nextPass = [int]$state.RunsCompleted + 1
if ($SimulateFinalPass) {
    $nextPass = $TotalPasses
}
if ($nextPass -gt $TotalPasses) {
    $nextPass = $TotalPasses
}

$cycleMode = Get-CycleMode -PassNumber $nextPass
Write-DemoLog -Path $logPath -Message "Current pass: $nextPass of $TotalPasses ($cycleMode)"
Write-DemoLog -Path $logPath -Message "Compliance cutoff: $($state.ComplianceCutoff)"

$plan = @(New-RemediationPlan -Rows $rows -DirectoryUsers $directoryUsers -State $state -PassNumber $nextPass)
Write-PlanOutputs -Plan $plan -OutputDirectory $OutputDirectory -LogPath $logPath

$blockingFailures = @($plan | Where-Object { $_.RemediationStage -in @("Reminder1Planned", "FinalReminderPlanned", "ForceResetPlanned") -and [string]::IsNullOrWhiteSpace($_.UserPrincipalName) })
if ($blockingFailures.Count -gt 0) {
    Write-DemoLog -Path $logPath -Level "ERROR" -Message "Blocking notification failures found: $($blockingFailures.Count). State will not advance."
    throw "Blocking notification failures found. State was not advanced."
}

if ($Mode -eq "SimulateApply") {
    if ($PSCmdlet.ShouldProcess("password remediation cycle", "simulate pass $nextPass")) {
        $simulatedPath = Write-SimulatedApplyLog -Plan $plan -OutputDirectory $OutputDirectory
        Write-DemoLog -Path $logPath -Message "Simulation log written to $(Split-Path -Leaf $simulatedPath)"

        $state.RunsCompleted = $nextPass
        $state.LastRunDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

        if ($nextPass -ge $TotalPasses) {
            Archive-DemoCycle -CsvPath $CsvPath -StatePath $statePath -State $state -ArchiveDirectory $ArchiveDirectory
            Save-CycleState -State $state -Path $statePath
            Remove-Item -LiteralPath $statePath -Force
            Write-DemoLog -Path $logPath -Message "Final pass complete. CSV/state copied to archive and active state removed."
        } else {
            Save-CycleState -State $state -Path $statePath
            Write-DemoLog -Path $logPath -Message "State advanced to RunsCompleted=$($state.RunsCompleted)."
        }
    }
} else {
    Write-DemoLog -Path $logPath -Message "PlanOnly mode: state was not advanced."
}

Write-Output "Password remediation cycle output written to $OutputDirectory"
