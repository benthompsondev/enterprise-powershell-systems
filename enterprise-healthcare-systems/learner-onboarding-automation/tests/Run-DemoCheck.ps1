$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ScriptPath = Join-Path $ProjectRoot "scripts\Invoke-AccountOnboardingDemo.ps1"
$CsvPath = Join-Path $ProjectRoot "examples\external-access-export.csv"
$MockDirectoryPath = Join-Path $ProjectRoot "examples\mock-directory-users.csv"
$OutputDirectory = Join-Path $ProjectRoot "output-test"

if (Test-Path -LiteralPath $OutputDirectory) {
    Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
}

powershell -ExecutionPolicy Bypass -File $ScriptPath `
    -CsvPath $CsvPath `
    -MockDirectoryPath $MockDirectoryPath `
    -OutputDirectory $OutputDirectory `
    -Mode SimulateApply

$ExpectedFiles = @(
    "external-access-plan.csv",
    "external-access-plan.json",
    "access-summary.csv",
    "directory-action-plan.csv",
    "exchange-mailbox-plan.csv",
    "service-desk-handoff-plan.csv",
    "notification-drafts.md",
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

$avery = $plan | Where-Object { $_.ExternalPersonId -eq "EXT-10001" } | Select-Object -First 1
if ($avery.AccessTypes -notmatch "Clinical App" -or $avery.AccessTypes -notmatch "Email") {
    throw "Expected repeated rows for EXT-10001 to merge into one access plan"
}

$morgan = $plan | Where-Object { $_.ExternalPersonId -eq "EXT-10002" } | Select-Object -First 1
if ($morgan.AccountState -ne "ExistingDisabled") {
    throw "Expected EXT-10002 to match a disabled mock directory account"
}

$jordan = $plan | Where-Object { $_.ExternalPersonId -eq "EXT-10003" } | Select-Object -First 1
if ($jordan.NeedsRemoteAccess -ne "True") {
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

Write-Output "Demo check passed."
