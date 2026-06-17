param(
    [string]$UserMigrationStateCsv = (Join-Path $PSScriptRoot "..\examples\user-migration-state.csv"),
    [string]$LicenseGroupStateCsv = (Join-Path $PSScriptRoot "..\examples\license-group-state.csv"),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\output\02-license-groups")
)

. (Join-Path $PSScriptRoot "O365MigrationDemo.Shared.ps1")

Initialize-DemoOutputDirectory -Path $OutputDirectory

$users = Import-RequiredCsv -Path $UserMigrationStateCsv -RequiredColumns @(
    "UserPrincipalName", "DisplayName", "MigrationState", "MailboxLocation", "LicenseStatus", "Enabled"
)
$licenseRows = Import-RequiredCsv -Path $LicenseGroupStateCsv -RequiredColumns @(
    "UserPrincipalName", "RequiredLicenseGroup", "CurrentLicenseGroups", "ExpectedMigrationState"
)

$userLookup = New-UserLookup -Users $users
$licensePlan = foreach ($licenseRow in $licenseRows) {
    $key = $licenseRow.UserPrincipalName.Trim().ToLowerInvariant()
    $foundUser = $userLookup.ContainsKey($key)
    $user = if ($foundUser) { $userLookup[$key] } else { $null }
    $licenseStatus = Get-LicenseGroupStatus -LicenseRow $licenseRow

    [pscustomobject]@{
        UserPrincipalName = $licenseRow.UserPrincipalName
        UserFoundInMigrationExport = $foundUser
        CurrentMigrationState = if ($foundUser) { $user.MigrationState } else { "Missing" }
        ExpectedMigrationState = $licenseRow.ExpectedMigrationState
        RequiredLicenseGroup = $licenseRow.RequiredLicenseGroup
        CurrentLicenseGroups = $licenseRow.CurrentLicenseGroups
        LicenseReadinessStatus = $licenseStatus
        PlannedDirectoryAction = switch ($licenseStatus) {
            "Ready" { "No group change needed" }
            "DuplicateLicensePath" { "Review and remove extra license-backed group" }
            "MissingRequiredLicenseGroup" { "Add required license-backed group after approval" }
            default { "Manual review required" }
        }
    }
}

$duplicateLicenseReview = @($licensePlan | Where-Object { $_.LicenseReadinessStatus -eq "DuplicateLicensePath" })

$licensePlan | Export-Csv -LiteralPath (Join-Path $OutputDirectory "user-license-group-plan.csv") -NoTypeInformation
$duplicateLicenseReview | Export-Csv -LiteralPath (Join-Path $OutputDirectory "duplicate-license-review.csv") -NoTypeInformation

Write-Output "O365 license group plan written to $OutputDirectory"
