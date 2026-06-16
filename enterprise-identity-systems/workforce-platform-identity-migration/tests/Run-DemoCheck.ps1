$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$OutputRoot = Join-Path $ProjectRoot "output-test"
$Examples = Join-Path $ProjectRoot "examples"

$SourceCsv = Join-Path $Examples "workforce-source-export.csv"
$DirectoryCsv = Join-Path $Examples "mock-directory-users.csv"
$MailboxActionCsv = Join-Path $Examples "mailbox-license-actions.csv"

$ValidationOut = Join-Path $OutputRoot "validation"
$AccountOut = Join-Path $OutputRoot "account-plan"
$OuReviewOut = Join-Path $OutputRoot "ou-review"
$MailboxOut = Join-Path $OutputRoot "mailbox-license"

try {
    if (Test-Path -LiteralPath $OutputRoot) {
        Remove-Item -LiteralPath $OutputRoot -Recurse -Force
    }

    powershell -ExecutionPolicy Bypass -File (Join-Path $ProjectRoot "scripts\Test-WorkforceSourceDataDemo.ps1") `
        -SourceCsv $SourceCsv `
        -MockDirectoryCsv $DirectoryCsv `
        -OutputDirectory $ValidationOut

    $validation = Import-Csv -LiteralPath (Join-Path $ValidationOut "validation-report.csv")
    if ($validation.Count -ne 5) { throw "Expected 5 validation rows, found $($validation.Count)" }
    if (-not ($validation.RecommendedAction -contains "CreateAccount")) { throw "Expected validation to identify a create-account row" }
    if (-not ($validation.RecommendedAction -contains "ReenableAndMoveToProjectOu")) { throw "Expected validation to identify a re-enable row" }
    if (-not ($validation.RecommendedAction -contains "TerminationReview")) { throw "Expected validation to identify a termination review row" }

    powershell -ExecutionPolicy Bypass -File (Join-Path $ProjectRoot "scripts\New-WorkforceAccountActionPlanDemo.ps1") `
        -ValidationReportCsv (Join-Path $ValidationOut "validation-report.csv") `
        -OutputDirectory $AccountOut

    $accountPlan = Import-Csv -LiteralPath (Join-Path $AccountOut "account-action-plan.csv")
    if (-not ($accountPlan.DirectoryActions -match "Create account")) { throw "Expected account plan to include create action" }
    if (-not ($accountPlan.DirectoryActions -match "Re-enable")) { throw "Expected account plan to include re-enable action" }
    if (-not ($accountPlan.GroupActions -match "APP-Workforce-Portal")) { throw "Expected default group planning" }

    powershell -ExecutionPolicy Bypass -File (Join-Path $ProjectRoot "scripts\Export-ProjectOuReviewDemo.ps1") `
        -MockDirectoryCsv $DirectoryCsv `
        -OutputDirectory $OuReviewOut

    $ouReview = Import-Csv -LiteralPath (Join-Path $OuReviewOut "project-ou-review.csv")
    if (-not ($ouReview.ReviewCategory -contains "LowGroupCountReview")) { throw "Expected low-group-count review category" }
    if (-not ($ouReview.ReviewCategory -contains "RecentLogonAfterTerminationMarker")) { throw "Expected recent-logon termination review category" }
    $ouReviewColumns = @($ouReview)[0].PSObject.Properties.Name
    if (-not ($ouReviewColumns -contains "ProjectAction")) { throw "Expected OU review to include project action tracking" }
    if (-not ($ouReviewColumns -contains "GoLiveReady")) { throw "Expected OU review to include go-live readiness tracking" }

    powershell -ExecutionPolicy Bypass -File (Join-Path $ProjectRoot "scripts\New-MailboxLicenseActionPlanDemo.ps1") `
        -ActionCsv $MailboxActionCsv `
        -MockDirectoryCsv $DirectoryCsv `
        -OutputDirectory $MailboxOut

    $mailboxPlan = Import-Csv -LiteralPath (Join-Path $MailboxOut "mailbox-license-action-plan.csv")
    if (-not ($mailboxPlan.Status -contains "MailboxLicensePlanCreated")) { throw "Expected mailbox/license plan rows" }
    if (-not ($mailboxPlan.Status -contains "TerminationPlanCreated")) { throw "Expected termination plan row" }

    foreach ($file in @(
        (Join-Path $ValidationOut "validation-summary.csv"),
        (Join-Path $AccountOut "account-action-summary.csv"),
        (Join-Path $OuReviewOut "project-ou-review-summary.csv"),
        (Join-Path $OuReviewOut "project-action-summary.csv"),
        (Join-Path $OuReviewOut "go-live-readiness-summary.csv"),
        (Join-Path $MailboxOut "mailbox-license-summary.csv")
    )) {
        if (-not (Test-Path -LiteralPath $file)) { throw "Expected output file missing: $file" }
    }

    Write-Output "Demo check passed."
}
finally {
    if (Test-Path -LiteralPath $OutputRoot) {
        Remove-Item -LiteralPath $OutputRoot -Recurse -Force
    }
}
