[CmdletBinding()]
param(
    [string]$InputCsv = (Join-Path $PSScriptRoot "..\examples\endpoint-profile-inventory.csv"),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\output"),
    [datetime]$Today = (Get-Date "2026-06-17")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw "Input CSV not found: $InputCsv"
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$excludedProfileTypes = @("System", "Service", "Support")
$profiles = Import-Csv -LiteralPath $InputCsv

$targets = foreach ($deviceGroup in ($profiles | Group-Object -Property DeviceName)) {
    $userProfiles = @(
        $deviceGroup.Group | Where-Object {
            $excludedProfileTypes -notcontains $_.ProfileType -and
            $_.ProfileName -notmatch '^(Default|Public|All Users)$' -and
            $_.ProfileName -notmatch '^(svc_|helpdesk\.|admin\.)'
        }
    )

    $staleProfiles = @(
        $userProfiles | Where-Object {
            (($Today - [datetime]$_.LastUseDate).Days -ge 90)
        }
    )

    $totalSizeMb = ($userProfiles | Measure-Object -Property SizeMb -Sum).Sum
    if ($null -eq $totalSizeMb) {
        $totalSizeMb = 0
    }

    $priority = if ($userProfiles.Count -ge 3 -or $totalSizeMb -ge 5000) {
        "High"
    }
    elseif ($staleProfiles.Count -gt 0 -or $totalSizeMb -ge 2000) {
        "Medium"
    }
    else {
        "Low"
    }

    [pscustomobject]@{
        DeviceName         = $deviceGroup.Name
        UserProfileCount   = $userProfiles.Count
        StaleProfileCount  = $staleProfiles.Count
        TotalProfileSizeGb = [math]::Round(($totalSizeMb / 1024), 2)
        CleanupPriority    = $priority
        ReviewNote         = if ($priority -eq "High") { "Review first for cleanup or rebuild planning." } else { "No urgent cleanup needed in demo data." }
    }
}

$outputPath = Join-Path $OutputDirectory "endpoint-profile-cleanup-targets.csv"
$targets | Sort-Object CleanupPriority, DeviceName | Export-Csv -LiteralPath $outputPath -NoTypeInformation
Write-Output "Wrote endpoint profile cleanup targets: $outputPath"
