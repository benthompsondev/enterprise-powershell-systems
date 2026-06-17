param(
    [string]$SharedMailboxAccessCsv = (Join-Path $PSScriptRoot "..\examples\shared-mailbox-access.csv"),
    [string]$UserMigrationStateCsv = (Join-Path $PSScriptRoot "..\examples\user-migration-state.csv"),
    [string]$LicenseGroupStateCsv = (Join-Path $PSScriptRoot "..\examples\license-group-state.csv"),
    [string]$PublicFolderInventoryCsv = (Join-Path $PSScriptRoot "..\examples\public-folder-inventory.csv"),
    [string]$MailboxIssueQueueCsv = (Join-Path $PSScriptRoot "..\examples\mailbox-issue-queue.csv"),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\output")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Import-RequiredCsv {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string[]]$RequiredColumns
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required CSV was not found: $Path"
    }

    $rows = @(Import-Csv -LiteralPath $Path)
    if ($rows.Count -eq 0) {
        throw "Required CSV has no rows: $Path"
    }

    $columns = @($rows[0].PSObject.Properties.Name)
    foreach ($column in $RequiredColumns) {
        if ($columns -notcontains $column) {
            throw "CSV '$Path' is missing required column '$column'"
        }
    }

    return $rows
}

function Write-RunLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $script:RunLogPath -Value "[$timestamp] $Message"
}

function Split-GroupList {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return @()
    }

    return @($Value -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function New-UserLookup {
    param([object[]]$Users)

    $lookup = @{}
    foreach ($user in $Users) {
        $key = $user.UserPrincipalName.Trim().ToLowerInvariant()
        if (-not $lookup.ContainsKey($key)) {
            $lookup[$key] = $user
        }
    }

    return $lookup
}

function Get-LicenseGroupStatus {
    param(
        [Parameter(Mandatory)]
        [object]$LicenseRow
    )

    $groups = @(Split-GroupList -Value $LicenseRow.CurrentLicenseGroups)
    $licenseGroups = @($groups | Where-Object { $_ -like "LIC-*" })
    $hasRequiredGroup = $groups -contains $LicenseRow.RequiredLicenseGroup

    if ($licenseGroups.Count -gt 1) {
        return "DuplicateLicensePath"
    }

    if (-not $hasRequiredGroup) {
        return "MissingRequiredLicenseGroup"
    }

    return "Ready"
}

function Get-MailboxRepairPlan {
    param(
        [Parameter(Mandatory)]
        [object]$Issue
    )

    switch ($Issue.IssueType) {
        "SoftDeletedMailbox" {
            "Review soft-deleted mailbox state, reconnect or restore mailbox, then rerun migration readiness check"
        }
        "DisabledAccountWithMailbox" {
            "Confirm account status with owner before migration. Do not re-enable automatically from a CSV"
        }
        "DuplicateLicensePath" {
            "Remove the extra license-backed group after confirming the intended license path"
        }
        default {
            "Manual review required before migration action"
        }
    }
}

function Get-PublicFolderAction {
    param(
        [Parameter(Mandatory)]
        [object]$Folder
    )

    switch ($Folder.RecommendedDisposition) {
        "ConvertToSharedMailbox" {
            "Confirm active owner, export folder content, create shared mailbox plan, remove public folder permissions after cutover"
        }
        "ArchiveAndRemovePermissions" {
            "Archive folder content, remove user permissions, and record evidence of cleanup"
        }
        default {
            "Review with owner before removing access or converting folder"
        }
    }
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$script:RunLogPath = Join-Path $OutputDirectory "run-log.txt"
Set-Content -LiteralPath $script:RunLogPath -Value "O365 migration readiness demo run"
Write-RunLog "Starting O365 migration readiness checks"

$sharedAccess = Import-RequiredCsv -Path $SharedMailboxAccessCsv -RequiredColumns @("MailboxName", "DelegatedUser", "PermissionType", "RequestedWave", "BusinessOwner")
$users = Import-RequiredCsv -Path $UserMigrationStateCsv -RequiredColumns @("UserPrincipalName", "DisplayName", "MigrationState", "MailboxLocation", "LicenseStatus", "Enabled")
$licenseRows = Import-RequiredCsv -Path $LicenseGroupStateCsv -RequiredColumns @("UserPrincipalName", "RequiredLicenseGroup", "CurrentLicenseGroups", "ExpectedMigrationState")
$publicFolders = Import-RequiredCsv -Path $PublicFolderInventoryCsv -RequiredColumns @("FolderPath", "Owner", "LastKnownUsage", "CurrentPermissionCount", "RecommendedDisposition")
$mailboxIssues = Import-RequiredCsv -Path $MailboxIssueQueueCsv -RequiredColumns @("UserPrincipalName", "IssueType", "CurrentState", "RequestedAction")

$userLookup = New-UserLookup -Users $users
Write-RunLog "Loaded fake migration data for $($users.Count) users and $($sharedAccess.Count) shared mailbox permission rows"

$permissionDetail = foreach ($row in $sharedAccess) {
    $delegatedKey = $row.DelegatedUser.Trim().ToLowerInvariant()
    $user = $null
    $foundUser = $userLookup.ContainsKey($delegatedKey)
    if ($foundUser) {
        $user = $userLookup[$delegatedKey]
    }

    $blockReason = if (-not $foundUser) {
        "Delegated user not found in migration state export"
    }
    elseif ($user.Enabled -ne "True") {
        "Delegated user account is disabled"
    }
    elseif ($user.MigrationState -ne "O365") {
        "Delegated user is not migrated to O365 yet"
    }
    elseif ($user.LicenseStatus -ne "Ready") {
        "Delegated user is migrated but licensing still needs review"
    }
    else {
        ""
    }

    [pscustomobject]@{
        MailboxName = $row.MailboxName
        DelegatedUser = $row.DelegatedUser
        PermissionType = $row.PermissionType
        RequestedWave = $row.RequestedWave
        BusinessOwner = $row.BusinessOwner
        DelegatedUserFound = $foundUser
        DelegatedUserMigrationState = if ($foundUser) { $user.MigrationState } else { "Missing" }
        DelegatedUserMailboxLocation = if ($foundUser) { $user.MailboxLocation } else { "Missing" }
        DelegatedUserLicenseStatus = if ($foundUser) { $user.LicenseStatus } else { "Missing" }
        ReadyForSharedMailboxMigration = [string]::IsNullOrWhiteSpace($blockReason)
        BlockReason = $blockReason
    }
}

$mailboxReadiness = foreach ($mailboxGroup in ($permissionDetail | Group-Object MailboxName)) {
    $rows = @($mailboxGroup.Group)
    $blockedRows = @($rows | Where-Object { $_.ReadyForSharedMailboxMigration -ne $true })
    $ready = $blockedRows.Count -eq 0

    [pscustomobject]@{
        MailboxName = $mailboxGroup.Name
        RequestedWave = ($rows | Select-Object -First 1).RequestedWave
        BusinessOwner = ($rows | Select-Object -First 1).BusinessOwner
        DelegatedUsersChecked = $rows.Count
        MigratedDelegates = @($rows | Where-Object { $_.DelegatedUserMigrationState -eq "O365" }).Count
        BlockedDelegates = $blockedRows.Count
        ReadyToMigrate = $ready
        ReadinessStatus = if ($ready) { "Ready" } else { "Blocked" }
        BlockReasons = if ($ready) { "" } else { (($blockedRows.BlockReason | Sort-Object -Unique) -join "; ") }
        RecommendedAction = if ($ready) {
            "Mailbox can be included in the next migration batch"
        }
        else {
            "Hold mailbox until delegated user blockers are resolved"
        }
    }
}

$licenseReadiness = foreach ($licenseRow in $licenseRows) {
    $key = $licenseRow.UserPrincipalName.Trim().ToLowerInvariant()
    $foundUser = $userLookup.ContainsKey($key)
    $user = if ($foundUser) { $userLookup[$key] } else { $null }
    $licenseStatus = Get-LicenseGroupStatus -LicenseRow $licenseRow

    [pscustomobject]@{
        UserPrincipalName = $licenseRow.UserPrincipalName
        ExpectedMigrationState = $licenseRow.ExpectedMigrationState
        CurrentMigrationState = if ($foundUser) { $user.MigrationState } else { "Missing" }
        RequiredLicenseGroup = $licenseRow.RequiredLicenseGroup
        CurrentLicenseGroups = $licenseRow.CurrentLicenseGroups
        LicenseReadinessStatus = $licenseStatus
        RecommendedAction = switch ($licenseStatus) {
            "Ready" { "No license group change needed" }
            "DuplicateLicensePath" { "Review and remove extra license-backed group" }
            "MissingRequiredLicenseGroup" { "Add required license-backed group when user is approved for O365" }
            default { "Manual review required" }
        }
    }
}

$duplicateLicenseReview = @($licenseReadiness | Where-Object { $_.LicenseReadinessStatus -eq "DuplicateLicensePath" })

$publicFolderPlan = foreach ($folder in $publicFolders) {
    [pscustomobject]@{
        FolderPath = $folder.FolderPath
        Owner = $folder.Owner
        LastKnownUsage = $folder.LastKnownUsage
        CurrentPermissionCount = $folder.CurrentPermissionCount
        RecommendedDisposition = $folder.RecommendedDisposition
        CleanupStatus = if ($folder.RecommendedDisposition -eq "ReviewWithOwner") { "NeedsOwnerReview" } else { "Planned" }
        PlannedAction = Get-PublicFolderAction -Folder $folder
    }
}

$mailboxRepairPlan = foreach ($issue in $mailboxIssues) {
    [pscustomobject]@{
        UserPrincipalName = $issue.UserPrincipalName
        IssueType = $issue.IssueType
        CurrentState = $issue.CurrentState
        RequestedAction = $issue.RequestedAction
        RepairPlan = Get-MailboxRepairPlan -Issue $issue
        SafeToAutomate = if ($issue.IssueType -eq "DuplicateLicensePath") { "ReviewFirst" } else { "No" }
    }
}

$summaryRows = @()
$summaryRows += [pscustomobject]@{ Area = "SharedMailboxes"; Status = "Ready"; Count = @($mailboxReadiness | Where-Object { $_.ReadinessStatus -eq "Ready" }).Count }
$summaryRows += [pscustomobject]@{ Area = "SharedMailboxes"; Status = "Blocked"; Count = @($mailboxReadiness | Where-Object { $_.ReadinessStatus -eq "Blocked" }).Count }
$summaryRows += [pscustomobject]@{ Area = "Licensing"; Status = "Ready"; Count = @($licenseReadiness | Where-Object { $_.LicenseReadinessStatus -eq "Ready" }).Count }
$summaryRows += [pscustomobject]@{ Area = "Licensing"; Status = "MissingRequiredLicenseGroup"; Count = @($licenseReadiness | Where-Object { $_.LicenseReadinessStatus -eq "MissingRequiredLicenseGroup" }).Count }
$summaryRows += [pscustomobject]@{ Area = "Licensing"; Status = "DuplicateLicensePath"; Count = $duplicateLicenseReview.Count }
$summaryRows += [pscustomobject]@{ Area = "PublicFolders"; Status = "Planned"; Count = @($publicFolderPlan | Where-Object { $_.CleanupStatus -eq "Planned" }).Count }
$summaryRows += [pscustomobject]@{ Area = "PublicFolders"; Status = "NeedsOwnerReview"; Count = @($publicFolderPlan | Where-Object { $_.CleanupStatus -eq "NeedsOwnerReview" }).Count }
$summaryRows += [pscustomobject]@{ Area = "MailboxIssues"; Status = "RepairPlanCreated"; Count = $mailboxRepairPlan.Count }

$permissionDetail | Export-Csv -LiteralPath (Join-Path $OutputDirectory "shared-mailbox-permission-detail.csv") -NoTypeInformation
$mailboxReadiness | Export-Csv -LiteralPath (Join-Path $OutputDirectory "shared-mailbox-readiness.csv") -NoTypeInformation
$licenseReadiness | Export-Csv -LiteralPath (Join-Path $OutputDirectory "user-license-readiness.csv") -NoTypeInformation
$duplicateLicenseReview | Export-Csv -LiteralPath (Join-Path $OutputDirectory "duplicate-license-review.csv") -NoTypeInformation
$publicFolderPlan | Export-Csv -LiteralPath (Join-Path $OutputDirectory "public-folder-cleanup-plan.csv") -NoTypeInformation
$mailboxRepairPlan | Export-Csv -LiteralPath (Join-Path $OutputDirectory "mailbox-issue-repair-plan.csv") -NoTypeInformation
$summaryRows | Export-Csv -LiteralPath (Join-Path $OutputDirectory "migration-readiness-summary.csv") -NoTypeInformation

Write-RunLog "Wrote migration readiness reports"
Write-Output "O365 migration readiness demo complete. Output: $OutputDirectory"
