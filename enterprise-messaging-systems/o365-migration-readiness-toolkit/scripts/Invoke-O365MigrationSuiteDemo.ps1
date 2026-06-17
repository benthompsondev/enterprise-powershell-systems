param(
    [string]$SharedMailboxAccessCsv = (Join-Path $PSScriptRoot "..\examples\shared-mailbox-access.csv"),
    [string]$UserMigrationStateCsv = (Join-Path $PSScriptRoot "..\examples\user-migration-state.csv"),
    [string]$LicenseGroupStateCsv = (Join-Path $PSScriptRoot "..\examples\license-group-state.csv"),
    [string]$PublicFolderInventoryCsv = (Join-Path $PSScriptRoot "..\examples\public-folder-inventory.csv"),
    [string]$MailboxIssueQueueCsv = (Join-Path $PSScriptRoot "..\examples\mailbox-issue-queue.csv"),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\output")
)

. (Join-Path $PSScriptRoot "O365MigrationDemo.Shared.ps1")

Initialize-DemoOutputDirectory -Path $OutputDirectory
$runLogPath = Join-Path $OutputDirectory "run-log.txt"
Set-Content -LiteralPath $runLogPath -Value "O365 migration suite demo run"

function Write-SuiteLog {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $runLogPath -Value "[$timestamp] $Message"
}

Write-SuiteLog "Starting separate O365 migration support scripts"

powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-UserMigrationWavePlanDemo.ps1") `
    -UserMigrationStateCsv $UserMigrationStateCsv `
    -LicenseGroupStateCsv $LicenseGroupStateCsv `
    -OutputDirectory (Join-Path $OutputDirectory "01-user-migration-wave")

powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "New-O365LicenseGroupPlanDemo.ps1") `
    -UserMigrationStateCsv $UserMigrationStateCsv `
    -LicenseGroupStateCsv $LicenseGroupStateCsv `
    -OutputDirectory (Join-Path $OutputDirectory "02-license-groups")

powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Test-SharedMailboxMigrationReadinessDemo.ps1") `
    -SharedMailboxAccessCsv $SharedMailboxAccessCsv `
    -UserMigrationStateCsv $UserMigrationStateCsv `
    -OutputDirectory (Join-Path $OutputDirectory "03-shared-mailboxes")

powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "New-PublicFolderRetirementPlanDemo.ps1") `
    -PublicFolderInventoryCsv $PublicFolderInventoryCsv `
    -OutputDirectory (Join-Path $OutputDirectory "04-public-folders")

powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "New-MailboxIssueRepairPlanDemo.ps1") `
    -MailboxIssueQueueCsv $MailboxIssueQueueCsv `
    -OutputDirectory (Join-Path $OutputDirectory "05-mailbox-repair")

$userWave = @(Import-Csv -LiteralPath (Join-Path $OutputDirectory "01-user-migration-wave\user-migration-wave-plan.csv"))
$licenses = @(Import-Csv -LiteralPath (Join-Path $OutputDirectory "02-license-groups\user-license-group-plan.csv"))
$sharedMailboxes = @(Import-Csv -LiteralPath (Join-Path $OutputDirectory "03-shared-mailboxes\shared-mailbox-migration-readiness.csv"))
$publicFolders = @(Import-Csv -LiteralPath (Join-Path $OutputDirectory "04-public-folders\public-folder-retirement-plan.csv"))
$repairs = @(Import-Csv -LiteralPath (Join-Path $OutputDirectory "05-mailbox-repair\mailbox-issue-repair-plan.csv"))

$summaryRows = @(
    [pscustomobject]@{ Area = "UserMigration"; Status = "AlreadyMigrated"; Count = @($userWave | Where-Object { $_.MigrationWaveAction -eq "AlreadyMigrated" }).Count }
    [pscustomobject]@{ Area = "UserMigration"; Status = "NeedsNextWaveWork"; Count = @($userWave | Where-Object { $_.MigrationWaveAction -ne "AlreadyMigrated" }).Count }
    [pscustomobject]@{ Area = "Licensing"; Status = "DuplicateLicensePath"; Count = @($licenses | Where-Object { $_.LicenseReadinessStatus -eq "DuplicateLicensePath" }).Count }
    [pscustomobject]@{ Area = "SharedMailboxes"; Status = "Ready"; Count = @($sharedMailboxes | Where-Object { $_.ReadinessStatus -eq "Ready" }).Count }
    [pscustomobject]@{ Area = "SharedMailboxes"; Status = "Blocked"; Count = @($sharedMailboxes | Where-Object { $_.ReadinessStatus -eq "Blocked" }).Count }
    [pscustomobject]@{ Area = "PublicFolders"; Status = "CleanupOrConversionPlanned"; Count = @($publicFolders | Where-Object { $_.CleanupStatus -eq "Planned" }).Count }
    [pscustomobject]@{ Area = "MailboxIssues"; Status = "RepairPlanCreated"; Count = $repairs.Count }
)

$summaryRows | Export-Csv -LiteralPath (Join-Path $OutputDirectory "migration-suite-summary.csv") -NoTypeInformation
Write-SuiteLog "Finished separate O365 migration support scripts"
Write-Output "O365 migration suite demo complete. Output: $OutputDirectory"
