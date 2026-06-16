$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ScriptPath = Join-Path $ProjectRoot "scripts\Invoke-AccountOnboardingDemo.ps1"
$CsvPath = Join-Path $ProjectRoot "examples\external-access-export.csv"
$MockDirectoryPath = Join-Path $ProjectRoot "examples\mock-directory-users.csv"
$OutputDirectory = Join-Path $ProjectRoot "output-test"

try {
    if (Test-Path -LiteralPath $OutputDirectory) {
        Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
    }

    powershell -ExecutionPolicy Bypass -File $ScriptPath `
        -CsvPath $CsvPath `
        -MockDirectoryPath $MockDirectoryPath `
        -OutputDirectory $OutputDirectory `
        -RunProfile RunA `
        -Mode SimulateApply

    $ExpectedFiles = @(
        "external-access-plan.csv",
        "external-access-plan.json",
        "access-summary.csv",
        "directory-action-plan.csv",
        "exchange-mailbox-plan.csv",
        "service-desk-handoff-plan.csv",
        "upstream-response-export.csv",
        "notification-drafts.md",
        "run-profile-manifest.json",
        "run-log.txt",
        "simulated-apply.log"
    )

    foreach ($file in $ExpectedFiles) {
        $path = Join-Path $OutputDirectory $file
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Expected output file was not created: $path"
        }
    }

    $plan = Import-Csv -LiteralPath (Join-Path $OutputDirectory "external-access-plan.csv")
    if ($plan.Count -ne 4) {
        throw "Expected 4 merged people in the plan, found $($plan.Count)"
    }

    $demoAlpha = $plan | Where-Object { $_.ExternalPersonId -eq "EXT-10001" } | Select-Object -First 1
    if ($demoAlpha.AccessTypes -notmatch "Clinical App" -or $demoAlpha.AccessTypes -notmatch "Email") {
        throw "Expected repeated rows for EXT-10001 to merge into one access plan"
    }

    $demoBravo = $plan | Where-Object { $_.ExternalPersonId -eq "EXT-10002" } | Select-Object -First 1
    if ($demoBravo.AccountState -ne "ExistingDisabled") {
        throw "Expected EXT-10002 to match a disabled mock directory account"
    }

    $demoCharlie = $plan | Where-Object { $_.ExternalPersonId -eq "EXT-10003" } | Select-Object -First 1
    if ($demoCharlie.NeedsRemoteAccess -ne "True") {
        throw "Expected EXT-10003 to flag remote access review"
    }

    $mailboxPlan = Import-Csv -LiteralPath (Join-Path $OutputDirectory "exchange-mailbox-plan.csv")
    $mailboxRows = @($mailboxPlan | Where-Object { $_.NeedsMailbox -eq "True" })
    if ($mailboxRows.Count -lt 2) {
        throw "Expected at least two people in the Exchange/mailbox planning report"
    }

    $directoryPlan = Import-Csv -LiteralPath (Join-Path $OutputDirectory "directory-action-plan.csv")
    if (-not ($directoryPlan.DirectoryActions -match "Re-enable directory account")) {
        throw "Expected directory action plan to include a re-enable path"
    }

    if (-not ($directoryPlan.GroupMembershipActions -match "Add or confirm group membership")) {
        throw "Expected directory action plan to include group membership planning"
    }

    $serviceDeskPlan = Import-Csv -LiteralPath (Join-Path $OutputDirectory "service-desk-handoff-plan.csv")
    if (-not ($serviceDeskPlan.ServiceDeskActions -match "ServiceNow-style ticket update")) {
        throw "Expected service desk handoff plan to include ServiceNow-style ticket updates"
    }

    if (-not ($serviceDeskPlan.EmailNotificationActions -match "Prepare notification email")) {
        throw "Expected service desk handoff plan to include notification email planning"
    }

    $response = Import-Csv -LiteralPath (Join-Path $OutputDirectory "upstream-response-export.csv")
    if ($response.Count -ne 9) {
        throw "Expected one upstream response row per access request, found $($response.Count)"
    }

    $firstDemoAlphaResponse = $response | Where-Object { $_.ExternalPersonId -eq "EXT-10001" } | Select-Object -First 1
    if ($firstDemoAlphaResponse.PasswordStatus -notmatch "Generated|Provided|Not changed") {
        throw "Expected first upstream response row to carry password status"
    }

    $secondDemoAlphaResponse = $response | Where-Object { $_.ExternalPersonId -eq "EXT-10001" } | Select-Object -Skip 1 -First 1
    if ($secondDemoAlphaResponse.PasswordStatus -ne "Included on first response row only") {
        throw "Expected later upstream response rows to suppress password status"
    }

    $manifest = Get-Content -LiteralPath (Join-Path $OutputDirectory "run-profile-manifest.json") -Raw | ConvertFrom-Json
    if ($manifest.RunProfile -ne "RunA") {
        throw "Expected run profile manifest to record RunA"
    }

    if (-not (Get-ChildItem -LiteralPath $OutputDirectory -Directory -Filter "backup-*" -ErrorAction SilentlyContinue)) {
        throw "Expected a dated backup folder with a copied source export"
    }

    Write-Output "Demo check passed."
}
finally {
    if (Test-Path -LiteralPath $OutputDirectory) {
        Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
    }
}
