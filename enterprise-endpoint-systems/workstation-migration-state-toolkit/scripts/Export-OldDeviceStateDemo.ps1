<#
.SYNOPSIS
Captures old workstation state before a hardware or Windows migration.

.DESCRIPTION
This sanitized demo keeps the shape of a real endpoint migration script. It creates
a per-device folder with inventory CSVs, writes a run log, and appends a row to a
master tracking CSV so a migration lead can see progress across many devices.

The default mode uses live Windows commands when available. For portfolio review
and GitHub Actions, pass -MockDataDirectory with fake CSV inputs.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$OldComputerName,

    [Parameter(Mandatory)]
    [string]$ReplacementComputerName,

    [Parameter(Mandatory)]
    [string]$TechnicianName,

    [string]$MigrationBatch = "Win11-Refresh-Demo",
    [string]$StateRootPath = ".\output\device-state",
    [string]$MasterTrackingCsv = ".\output\migration-master-tracking.csv",
    [string]$MockDataDirectory,
    [switch]$RestartAfterCapture
)

$ErrorActionPreference = "Stop"

function Write-RunLog {
    param([string]$Path, [string]$Message)
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Write-Output $line
    Add-Content -LiteralPath $Path -Value $line
}

function Import-MockCsv {
    param([string]$MockDirectory, [string]$FileName)
    if ([string]::IsNullOrWhiteSpace($MockDirectory)) {
        return $null
    }
    $path = Join-Path $MockDirectory $FileName
    if (Test-Path -LiteralPath $path) {
        return Import-Csv -LiteralPath $path
    }
    return $null
}

function Get-InstalledProgramInventory {
    param([string]$MockDirectory)

    $mock = Import-MockCsv -MockDirectory $MockDirectory -FileName "installed-programs.csv"
    if ($null -ne $mock) {
        return $mock
    }

    $views = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($view in $views) {
        Get-ItemProperty -Path $view -ErrorAction SilentlyContinue |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_.DisplayName) } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
    }
}

function Get-PrinterInventory {
    param([string]$MockDirectory)

    $mock = Import-MockCsv -MockDirectory $MockDirectory -FileName "printers.csv"
    if ($null -ne $mock) {
        return $mock
    }

    if (Get-Command Get-Printer -ErrorAction SilentlyContinue) {
        Get-Printer | Select-Object Name, DriverName, PortName, Shared, Type, Default
    }
}

function Get-LocalGroupInventory {
    param([string]$MockDirectory)

    $mock = Import-MockCsv -MockDirectory $MockDirectory -FileName "local-groups.csv"
    if ($null -ne $mock) {
        return $mock
    }

    $rows = New-Object System.Collections.Generic.List[object]
    if (Get-Command Get-LocalGroup -ErrorAction SilentlyContinue) {
        foreach ($group in Get-LocalGroup) {
            $members = @(Get-LocalGroupMember -Group $group.Name -ErrorAction SilentlyContinue)
            foreach ($member in $members) {
                $rows.Add([pscustomobject]@{
                    GroupName  = $group.Name
                    MemberName = $member.Name
                    MemberType = $member.ObjectClass
                    Source     = "LocalGroup"
                })
            }
        }
    }
    return $rows
}

function Get-ComputerBaseline {
    param([string]$ComputerName)

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $system = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    [pscustomobject]@{
        ComputerName     = $ComputerName
        CapturedAt       = Get-Date -Format "s"
        Manufacturer     = $system.Manufacturer
        Model            = $system.Model
        SerialNumber     = (Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue).SerialNumber
        OperatingSystem  = $os.Caption
        BuildNumber      = $os.BuildNumber
        LoggedOnUser     = $system.UserName
        MigrationBatch   = $MigrationBatch
        ReplacementName  = $ReplacementComputerName
    }
}

function Export-SafeCsv {
    param([object[]]$Rows, [string]$Path)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    @($Rows) | Export-Csv -LiteralPath $Path -NoTypeInformation
}

function Add-MasterTrackingRow {
    param([string]$Path, [object]$Row)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $exists = Test-Path -LiteralPath $Path
    @($Row) | Export-Csv -LiteralPath $Path -NoTypeInformation -Append:$exists
}

$deviceFolderName = "{0}_to_{1}" -f $OldComputerName, $ReplacementComputerName
$deviceFolder = Join-Path $StateRootPath $deviceFolderName
$logPath = Join-Path $deviceFolder "capture-run-log.txt"

if (-not (Test-Path -LiteralPath $deviceFolder)) {
    New-Item -ItemType Directory -Path $deviceFolder -Force | Out-Null
}
Set-Content -LiteralPath $logPath -Value "Old device capture started: $(Get-Date -Format "s")"

Write-RunLog -Path $logPath -Message "Capturing state for $OldComputerName before replacement with $ReplacementComputerName."

$programs = @(Get-InstalledProgramInventory -MockDirectory $MockDataDirectory)
$printers = @(Get-PrinterInventory -MockDirectory $MockDataDirectory)
$groups = @(Get-LocalGroupInventory -MockDirectory $MockDataDirectory)
$baseline = Get-ComputerBaseline -ComputerName $OldComputerName

Export-SafeCsv -Rows $programs -Path (Join-Path $deviceFolder "installed-programs.csv")
Export-SafeCsv -Rows $printers -Path (Join-Path $deviceFolder "printers.csv")
Export-SafeCsv -Rows $groups -Path (Join-Path $deviceFolder "local-group-memberships.csv")
Export-SafeCsv -Rows @($baseline) -Path (Join-Path $deviceFolder "computer-baseline.csv")

$manifest = [pscustomobject]@{
    OldComputerName         = $OldComputerName
    ReplacementComputerName = $ReplacementComputerName
    TechnicianName          = $TechnicianName
    MigrationBatch          = $MigrationBatch
    CapturedAt              = Get-Date -Format "s"
    DeviceFolder            = $deviceFolder
    ProgramCount            = $programs.Count
    PrinterCount            = $printers.Count
    LocalGroupRows          = $groups.Count
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $deviceFolder "migration-manifest.json")

Add-MasterTrackingRow -Path $MasterTrackingCsv -Row ([pscustomobject]@{
    Timestamp               = Get-Date -Format "s"
    Stage                   = "OldDeviceCapture"
    MigrationBatch          = $MigrationBatch
    TechnicianName          = $TechnicianName
    OldComputerName         = $OldComputerName
    ReplacementComputerName = $ReplacementComputerName
    Status                  = "Captured"
    ProgramCount            = $programs.Count
    PrinterCount            = $printers.Count
    LocalGroupRows          = $groups.Count
    DeviceFolder            = $deviceFolder
})

if ($RestartAfterCapture) {
    Write-RunLog -Path $logPath -Message "Restart requested. Sanitized demo logs the request instead of forcing a restart."
} else {
    Write-RunLog -Path $logPath -Message "Restart skipped."
}

Write-RunLog -Path $logPath -Message "Old device capture complete."
