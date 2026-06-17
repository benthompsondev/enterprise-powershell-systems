param(
    [string]$SharedMailboxAccessCsv = (Join-Path $PSScriptRoot "..\examples\shared-mailbox-access.csv"),
    [string]$UserMigrationStateCsv = (Join-Path $PSScriptRoot "..\examples\user-migration-state.csv"),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\output\03-shared-mailboxes")
)

. (Join-Path $PSScriptRoot "O365MigrationDemo.Shared.ps1")

Initialize-DemoOutputDirectory -Path $OutputDirectory

$sharedAccess = Import-RequiredCsv -Path $SharedMailboxAccessCsv -RequiredColumns @(
    "MailboxName", "DelegatedUser", "PermissionType", "RequestedWave", "BusinessOwner"
)
$users = Import-RequiredCsv -Path $UserMigrationStateCsv -RequiredColumns @(
    "UserPrincipalName", "DisplayName", "MigrationState", "MailboxLocation", "LicenseStatus", "Enabled"
)

$userLookup = New-UserLookup -Users $users
$permissionDetail = foreach ($row in $sharedAccess) {
    $delegatedKey = $row.DelegatedUser.Trim().ToLowerInvariant()
    $foundUser = $userLookup.ContainsKey($delegatedKey)
    $user = if ($foundUser) { $userLookup[$delegatedKey] } else { $null }

    $blockReason = if (-not $foundUser) {
        "Delegated user not found in migration export"
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
        ReadinessStatus = if ($ready) { "Ready" } else { "Blocked" }
        BlockReasons = if ($ready) { "" } else { (($blockedRows.BlockReason | Sort-Object -Unique) -join "; ") }
        MigrationPlanAction = if ($ready) {
            "Include shared mailbox in next migration batch"
        }
        else {
            "Hold shared mailbox until every delegated user is migrated and licensed"
        }
    }
}

$permissionDetail | Export-Csv -LiteralPath (Join-Path $OutputDirectory "shared-mailbox-permission-detail.csv") -NoTypeInformation
$mailboxReadiness | Export-Csv -LiteralPath (Join-Path $OutputDirectory "shared-mailbox-migration-readiness.csv") -NoTypeInformation

Write-Output "Shared mailbox migration readiness written to $OutputDirectory"
