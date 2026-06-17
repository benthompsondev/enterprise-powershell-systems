[CmdletBinding()]
param(
    [string]$InputCsv = (Join-Path $PSScriptRoot "..\examples\windows-update-inventory.csv"),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\output")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw "Input CSV not found: $InputCsv"
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$today = Get-Date "2026-06-17"
$inventory = Import-Csv -LiteralPath $InputCsv

$targets = foreach ($device in $inventory) {
    $installed = @($device.InstalledKbs -split ';' | Where-Object { $_ })
    $hasTargetKb = $installed -contains $device.TargetKb
    $lastSeen = [datetime]$device.LastSeen
    $staleInventory = (($today - $lastSeen).Days -gt 30)
    $freeDisk = [decimal]$device.FreeDiskGb
    $pendingReboot = [System.Convert]::ToBoolean($device.PendingReboot)

    $action = if ($hasTargetKb) {
        "NoAction"
    }
    elseif ($staleInventory) {
        "RefreshInventory"
    }
    elseif ($device.OperatingSystem -notmatch "Windows 11") {
        "ReviewUnsupportedOs"
    }
    elseif ($freeDisk -lt 5) {
        "FreeDiskThenRetry"
    }
    elseif ($pendingReboot) {
        "RebootThenRecheck"
    }
    elseif ($device.ErrorCode) {
        "RemediateUpdateError"
    }
    else {
        "InstallTargetUpdate"
    }

    [pscustomobject]@{
        DeviceName          = $device.DeviceName
        OperatingSystem     = $device.OperatingSystem
        TargetKb            = $device.TargetKb
        HasTargetKb         = $hasTargetKb
        ErrorCode           = $device.ErrorCode
        FreeDiskGb          = $freeDisk
        PendingReboot       = $pendingReboot
        RecommendedAction   = $action
        SupportOwner        = $device.SupportOwner
    }
}

$outputPath = Join-Path $OutputDirectory "windows-update-remediation-targets.csv"
$targets | Export-Csv -LiteralPath $outputPath -NoTypeInformation
Write-Output "Wrote Windows update remediation targets: $outputPath"
