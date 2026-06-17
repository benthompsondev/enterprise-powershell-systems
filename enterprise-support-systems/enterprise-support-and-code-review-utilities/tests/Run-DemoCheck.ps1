$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ScriptPath = Join-Path $ProjectRoot "scripts\Invoke-SupportUtilitySuiteDemo.ps1"
$OutputDirectory = Join-Path $ProjectRoot "output-test"

try {
    if (Test-Path -LiteralPath $OutputDirectory) {
        Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
    }

    powershell -ExecutionPolicy Bypass -File $ScriptPath -OutputDirectory $OutputDirectory

    $expectedFiles = @(
        "dhcp-reservation-review.csv",
        "windows-update-remediation-targets.csv",
        "endpoint-profile-cleanup-targets.csv",
        "security-group-audit-export.csv",
        "security-group-audit-summary.csv",
        "support-utility-suite-summary.csv"
    )

    foreach ($file in $expectedFiles) {
        $path = Join-Path $OutputDirectory $file
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Expected output file was not created: $path"
        }
    }

    $dhcp = Import-Csv -LiteralPath (Join-Path $OutputDirectory "dhcp-reservation-review.csv")
    if (-not ($dhcp | Where-Object { $_.ReviewIssues -match "DuplicateRequestedIp" })) {
        throw "Expected DHCP review to flag a duplicate IP request."
    }

    $updates = Import-Csv -LiteralPath (Join-Path $OutputDirectory "windows-update-remediation-targets.csv")
    if (-not ($updates | Where-Object { $_.RecommendedAction -eq "FreeDiskThenRetry" })) {
        throw "Expected Windows update report to flag a disk cleanup target."
    }

    $profiles = Import-Csv -LiteralPath (Join-Path $OutputDirectory "endpoint-profile-cleanup-targets.csv")
    $highPriority = $profiles | Where-Object { $_.CleanupPriority -eq "High" } | Select-Object -First 1
    if ($null -eq $highPriority) {
        throw "Expected endpoint profile report to include a high-priority cleanup target."
    }

    $audit = Import-Csv -LiteralPath (Join-Path $OutputDirectory "security-group-audit-export.csv")
    if (-not ($audit | Where-Object { $_.ReviewFlags -match "DisabledAccount" })) {
        throw "Expected security group audit to flag a disabled account."
    }

    Write-Output "Demo check passed."
}
finally {
    if (Test-Path -LiteralPath $OutputDirectory) {
        Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
    }
}
