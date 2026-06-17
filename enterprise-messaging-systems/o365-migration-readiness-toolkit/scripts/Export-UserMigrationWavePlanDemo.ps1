param(
    [string]$UserMigrationStateCsv = (Join-Path $PSScriptRoot "..\examples\user-migration-state.csv"),
    [string]$LicenseGroupStateCsv = (Join-Path $PSScriptRoot "..\examples\license-group-state.csv"),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\output\01-user-migration-wave")
)

. (Join-Path $PSScriptRoot "O365MigrationDemo.Shared.ps1")

Initialize-DemoOutputDirectory -Path $OutputDirectory

$users = Import-RequiredCsv -Path $UserMigrationStateCsv -RequiredColumns @(
    "UserPrincipalName", "DisplayName", "MigrationState", "MailboxLocation", "LicenseStatus", "Enabled"
)
$licenseRows = Import-RequiredCsv -Path $LicenseGroupStateCsv -RequiredColumns @(
    "UserPrincipalName", "RequiredLicenseGroup", "CurrentLicenseGroups", "ExpectedMigrationState"
)

$licenseLookup = New-LicenseLookup -LicenseRows $licenseRows
$migrationPlan = foreach ($user in $users) {
    $key = $user.UserPrincipalName.Trim().ToLowerInvariant()
    $licenseRow = if ($licenseLookup.ContainsKey($key)) { $licenseLookup[$key] } else { $null }
    $licenseStatus = if ($licenseRow) { Get-LicenseGroupStatus -LicenseRow $licenseRow } else { "MissingFromLicenseExport" }

    $action = if ($user.Enabled -ne "True") {
        "HoldDisabledAccount"
    }
    elseif ($user.MigrationState -eq "O365" -and $licenseStatus -eq "Ready") {
        "AlreadyMigrated"
    }
    elseif ($licenseStatus -eq "DuplicateLicensePath") {
        "CleanupLicenseBeforeNextWave"
    }
    elseif ($licenseStatus -eq "MissingRequiredLicenseGroup") {
        "AddLicenseGroupBeforeMigration"
    }
    elseif ($licenseStatus -eq "MissingFromLicenseExport") {
        "MissingDataReview"
    }
    else {
        "ReadyForMailboxMigration"
    }

    [pscustomobject]@{
        UserPrincipalName = $user.UserPrincipalName
        DisplayName = $user.DisplayName
        CurrentMigrationState = $user.MigrationState
        MailboxLocation = $user.MailboxLocation
        AccountEnabled = $user.Enabled
        LicenseReadinessStatus = $licenseStatus
        MigrationWaveAction = $action
        WhatThisAnswered = switch ($action) {
            "AlreadyMigrated" { "User is already on O365 and does not need to be in the next wave" }
            "ReadyForMailboxMigration" { "User has enough data to be included in the next migration batch" }
            "AddLicenseGroupBeforeMigration" { "User needs the license-backed AD group before migration" }
            "CleanupLicenseBeforeNextWave" { "User needs duplicate licensing cleaned up before more changes" }
            "HoldDisabledAccount" { "Disabled account should not be migrated automatically" }
            default { "Migration team needs more source data before deciding" }
        }
    }
}

$dataGapReport = @($migrationPlan | Where-Object {
    $_.MigrationWaveAction -in @("MissingDataReview", "HoldDisabledAccount", "CleanupLicenseBeforeNextWave")
})

$migrationPlan | Export-Csv -LiteralPath (Join-Path $OutputDirectory "user-migration-wave-plan.csv") -NoTypeInformation
$dataGapReport | Export-Csv -LiteralPath (Join-Path $OutputDirectory "migration-data-gap-report.csv") -NoTypeInformation

Write-Output "User migration wave plan written to $OutputDirectory"
