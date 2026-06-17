$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$OutputRoot = Join-Path $ProjectRoot "output-test"

try {
    if (Test-Path -LiteralPath $OutputRoot) {
        Remove-Item -LiteralPath $OutputRoot -Recurse -Force
    }

    powershell -ExecutionPolicy Bypass -File (Join-Path $ProjectRoot "scripts\Invoke-O365MigrationReadinessDemo.ps1") `
        -OutputDirectory $OutputRoot

    $sharedReadiness = @(Import-Csv -LiteralPath (Join-Path $OutputRoot "shared-mailbox-readiness.csv"))
    if ($sharedReadiness.Count -ne 3) { throw "Expected 3 shared mailbox readiness rows, found $($sharedReadiness.Count)" }
    if (-not ($sharedReadiness.ReadinessStatus -contains "Ready")) { throw "Expected at least one shared mailbox to be ready" }
    if (-not ($sharedReadiness.ReadinessStatus -contains "Blocked")) { throw "Expected at least one shared mailbox to be blocked" }
    if (-not ($sharedReadiness.BlockReasons -match "not migrated")) { throw "Expected delegated user migration blocker" }

    $licenseReadiness = @(Import-Csv -LiteralPath (Join-Path $OutputRoot "user-license-readiness.csv"))
    if (-not ($licenseReadiness.LicenseReadinessStatus -contains "Ready")) { throw "Expected ready license rows" }
    if (-not ($licenseReadiness.LicenseReadinessStatus -contains "MissingRequiredLicenseGroup")) { throw "Expected missing license group rows" }
    if (-not ($licenseReadiness.LicenseReadinessStatus -contains "DuplicateLicensePath")) { throw "Expected duplicate license path row" }

    $duplicates = @(Import-Csv -LiteralPath (Join-Path $OutputRoot "duplicate-license-review.csv"))
    if ($duplicates.Count -lt 1) { throw "Expected duplicate license review output" }

    $publicFolderPlan = @(Import-Csv -LiteralPath (Join-Path $OutputRoot "public-folder-cleanup-plan.csv"))
    if (-not ($publicFolderPlan.RecommendedDisposition -contains "ConvertToSharedMailbox")) { throw "Expected public folder conversion plan" }
    if (-not ($publicFolderPlan.CleanupStatus -contains "NeedsOwnerReview")) { throw "Expected owner review public folder row" }

    $repairPlan = @(Import-Csv -LiteralPath (Join-Path $OutputRoot "mailbox-issue-repair-plan.csv"))
    if (-not ($repairPlan.IssueType -contains "SoftDeletedMailbox")) { throw "Expected soft-deleted mailbox repair plan" }

    $summary = @(Import-Csv -LiteralPath (Join-Path $OutputRoot "migration-readiness-summary.csv"))
    if (-not ($summary.Area -contains "SharedMailboxes")) { throw "Expected shared mailbox summary rows" }
    if (-not ($summary.Area -contains "MailboxIssues")) { throw "Expected mailbox issue summary rows" }

    foreach ($file in @(
        "shared-mailbox-permission-detail.csv",
        "shared-mailbox-readiness.csv",
        "user-license-readiness.csv",
        "duplicate-license-review.csv",
        "public-folder-cleanup-plan.csv",
        "mailbox-issue-repair-plan.csv",
        "migration-readiness-summary.csv",
        "run-log.txt"
    )) {
        $path = Join-Path $OutputRoot $file
        if (-not (Test-Path -LiteralPath $path)) { throw "Expected output file missing: $file" }
    }

    Write-Output "Demo check passed."
}
finally {
    if (Test-Path -LiteralPath $OutputRoot) {
        Remove-Item -LiteralPath $OutputRoot -Recurse -Force
    }
}
