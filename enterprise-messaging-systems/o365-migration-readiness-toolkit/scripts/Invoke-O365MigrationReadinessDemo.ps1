param(
    [string]$SharedMailboxAccessCsv = (Join-Path $PSScriptRoot "..\examples\shared-mailbox-access.csv"),
    [string]$UserMigrationStateCsv = (Join-Path $PSScriptRoot "..\examples\user-migration-state.csv"),
    [string]$LicenseGroupStateCsv = (Join-Path $PSScriptRoot "..\examples\license-group-state.csv"),
    [string]$PublicFolderInventoryCsv = (Join-Path $PSScriptRoot "..\examples\public-folder-inventory.csv"),
    [string]$MailboxIssueQueueCsv = (Join-Path $PSScriptRoot "..\examples\mailbox-issue-queue.csv"),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\output")
)

$ErrorActionPreference = "Stop"

# Kept as a compatibility wrapper. The newer public demo is split into the same
# kind of separate support scripts the real migration needed.
powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Invoke-O365MigrationSuiteDemo.ps1") `
    -SharedMailboxAccessCsv $SharedMailboxAccessCsv `
    -UserMigrationStateCsv $UserMigrationStateCsv `
    -LicenseGroupStateCsv $LicenseGroupStateCsv `
    -PublicFolderInventoryCsv $PublicFolderInventoryCsv `
    -MailboxIssueQueueCsv $MailboxIssueQueueCsv `
    -OutputDirectory $OutputDirectory
