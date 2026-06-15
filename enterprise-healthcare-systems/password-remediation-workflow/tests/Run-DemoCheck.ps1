$ErrorActionPreference = "Stop"
$ConfirmPreference = "None"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$MainScriptPath = Join-Path $ProjectRoot "scripts\Invoke-PasswordRemediationDemo.ps1"
$ConverterScriptPath = Join-Path $ProjectRoot "scripts\Convert-WeakPasswordExportDemo.ps1"
$RawCsvPath = Join-Path $ProjectRoot "examples\raw-security-export.csv"
$CsvPath = Join-Path $ProjectRoot "examples\password-review-export.csv"
$MockDirectoryPath = Join-Path $ProjectRoot "examples\mock-directory-users.csv"
$OutputDirectory = Join-Path $ProjectRoot "output-test"
$InputFolder = Join-Path $OutputDirectory "Monthly_file"
$StateDirectory = Join-Path $OutputDirectory "State"
$ArchiveDirectory = Join-Path $OutputDirectory "Archive"

try {
    if (Test-Path -LiteralPath $OutputDirectory) {
        Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
    }

    New-Item -ItemType Directory -Path $InputFolder -Force | Out-Null

    & $ConverterScriptPath `
        -SourceCsv $RawCsvPath `
        -InputFolder $InputFolder `
        -EmailDomain "example.local" `
        -OutputName "weak-password-converted.csv"

    $convertedCsv = Join-Path $InputFolder "weak-password-converted.csv"
    if (-not (Test-Path -LiteralPath $convertedCsv)) {
        throw "Expected converter to create $convertedCsv"
    }

    $converted = Import-Csv -LiteralPath $convertedCsv
    if ($converted.Count -ne 6 -or -not ($converted[0].PSObject.Properties.Name -contains "UserPrincipalName")) {
        throw "Expected converter to create six rows with UserPrincipalName"
    }

    $duplicateBlocked = $false
    try {
        & $ConverterScriptPath `
            -SourceCsv $RawCsvPath `
            -InputFolder $InputFolder `
            -EmailDomain "example.local" `
            -OutputName "second-file.csv"
    } catch {
        $duplicateBlocked = $true
    }
    if (-not $duplicateBlocked) {
        throw "Expected converter to block a second active CSV"
    }

    & $MainScriptPath `
        -CsvPath $CsvPath `
        -MockDirectoryPath $MockDirectoryPath `
        -OutputDirectory $OutputDirectory `
        -StateDirectory $StateDirectory `
        -ArchiveDirectory $ArchiveDirectory `
        -Mode SimulateApply `
        -ForceRun

    $statePath = Join-Path $StateDirectory "cycle_state.json"
    if (-not (Test-Path -LiteralPath $statePath)) {
        throw "Expected active state after pass 1"
    }

    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($state.RunsCompleted -ne 1) {
        throw "Expected RunsCompleted=1 after pass 1"
    }

    $plan = Import-Csv -LiteralPath (Join-Path $OutputDirectory "password-remediation-plan.csv")
    if (-not ($plan.RemediationStage -contains "Reminder1Planned")) {
        throw "Expected pass 1 to include Reminder1Planned"
    }

    $duplicateRunBlocked = $false
    try {
        & $MainScriptPath `
            -CsvPath $CsvPath `
            -MockDirectoryPath $MockDirectoryPath `
            -OutputDirectory $OutputDirectory `
            -StateDirectory $StateDirectory `
            -ArchiveDirectory $ArchiveDirectory `
            -Mode SimulateApply
    } catch {
        $duplicateRunBlocked = $true
    }
    if (-not $duplicateRunBlocked) {
        throw "Expected duplicate-run guard to block an immediate second pass without -ForceRun"
    }

    & $MainScriptPath `
        -CsvPath $CsvPath `
        -MockDirectoryPath $MockDirectoryPath `
        -OutputDirectory $OutputDirectory `
        -StateDirectory $StateDirectory `
        -ArchiveDirectory $ArchiveDirectory `
        -Mode SimulateApply `
        -ForceRun

    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($state.RunsCompleted -ne 2) {
        throw "Expected RunsCompleted=2 after pass 2"
    }

    $plan = Import-Csv -LiteralPath (Join-Path $OutputDirectory "password-remediation-plan.csv")
    if (-not ($plan.RemediationStage -contains "FinalReminderPlanned")) {
        throw "Expected pass 2 to include FinalReminderPlanned"
    }

    & $MainScriptPath `
        -CsvPath $CsvPath `
        -MockDirectoryPath $MockDirectoryPath `
        -OutputDirectory $OutputDirectory `
        -StateDirectory $StateDirectory `
        -ArchiveDirectory $ArchiveDirectory `
        -Mode SimulateApply `
        -ForceRun

    if (Test-Path -LiteralPath $statePath) {
        throw "Expected active state file to be removed after final pass"
    }

    $plan = Import-Csv -LiteralPath (Join-Path $OutputDirectory "password-remediation-plan.csv")
    if (-not ($plan.RemediationStage -contains "ForceResetPlanned")) {
        throw "Expected final pass to include ForceResetPlanned"
    }

    if (-not (Get-ChildItem -LiteralPath $ArchiveDirectory -Recurse -Filter cycle_state.json -File -ErrorAction SilentlyContinue)) {
        throw "Expected archived cycle state after final pass"
    }

    $service = $plan | Where-Object { $_.SamAccountName -eq "svc-demo-reporting" } | Select-Object -First 1
    if ($service.Category -ne "ServiceOrSpecialAccount" -or $service.RemediationStage -ne "Skip") {
        throw "Expected service account to be skipped"
    }

    $compliant = $plan | Where-Object { $_.SamAccountName -eq "demo.charlie" } | Select-Object -First 1
    if ($compliant.RemediationStage -ne "Compliant") {
        throw "Expected user with post-cutoff PasswordLastSet to be compliant"
    }

    foreach ($file in @("password-remediation-plan.csv", "password-remediation-plan.json", "remediation-summary.csv", "notification-drafts.md", "audit-log.txt", "simulated-apply.log")) {
        $path = Join-Path $OutputDirectory $file
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Expected output file was not created: $path"
        }
    }

    Write-Output "Demo check passed."
}
finally {
    if (Test-Path -LiteralPath $OutputDirectory) {
        Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
    }
}
