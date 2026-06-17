[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\output")
)

$ErrorActionPreference = "Stop"

if (Test-Path -LiteralPath $OutputDirectory) {
    Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$scripts = @(
    "New-DhcpReservationReviewDemo.ps1",
    "Get-WindowsUpdateRemediationTargetsDemo.ps1",
    "Get-EndpointProfileCleanupTargetsDemo.ps1",
    "Export-SecurityGroupAuditDemo.ps1"
)

foreach ($script in $scripts) {
    $scriptPath = Join-Path $PSScriptRoot $script
    & $scriptPath -OutputDirectory $OutputDirectory
}

$summary = @(
    [pscustomobject]@{ Utility = "DHCP reservation review"; OutputFile = "dhcp-reservation-review.csv"; Rows = @(Import-Csv -LiteralPath (Join-Path $OutputDirectory "dhcp-reservation-review.csv")).Count }
    [pscustomobject]@{ Utility = "Windows update remediation"; OutputFile = "windows-update-remediation-targets.csv"; Rows = @(Import-Csv -LiteralPath (Join-Path $OutputDirectory "windows-update-remediation-targets.csv")).Count }
    [pscustomobject]@{ Utility = "Endpoint profile cleanup"; OutputFile = "endpoint-profile-cleanup-targets.csv"; Rows = @(Import-Csv -LiteralPath (Join-Path $OutputDirectory "endpoint-profile-cleanup-targets.csv")).Count }
    [pscustomobject]@{ Utility = "Security group audit"; OutputFile = "security-group-audit-export.csv"; Rows = @(Import-Csv -LiteralPath (Join-Path $OutputDirectory "security-group-audit-export.csv")).Count }
)

$summaryPath = Join-Path $OutputDirectory "support-utility-suite-summary.csv"
$summary | Export-Csv -LiteralPath $summaryPath -NoTypeInformation

Write-Output "Wrote support utility suite summary: $summaryPath"
