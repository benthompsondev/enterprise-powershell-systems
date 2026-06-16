<#
.SYNOPSIS
Builds a restore plan for a replacement workstation from captured old-device state.

.DESCRIPTION
This sanitized demo mirrors the second step of a workstation migration workflow.
It reads the old-device capture folder, plans what can be restored on the new
device, writes printer and application restore reports, and appends to the same
master tracking CSV used by the capture step.

By default this script plans and simulates work. It does not rename a computer,
install software, add printers, or restart Windows unless you replace the demo
logic with environment-specific implementation.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$NewComputerName,

    [Parameter(Mandatory)]
    [string]$CapturedStatePath,

    [Parameter(Mandatory)]
    [string]$TechnicianName,

    [string]$MigrationBatch = "Win11-Refresh-Demo",
    [string]$OutputDirectory = ".\output\restore",
    [string]$MasterTrackingCsv = ".\output\migration-master-tracking.csv",
    [ValidateSet("PlanOnly", "SimulateApply")]
    [string]$Mode = "PlanOnly",
    [switch]$RestartAfterRestore
)

$ErrorActionPreference = "Stop"

function Write-RunLog {
    param([string]$Path, [string]$Message)
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Write-Output $line
    Add-Content -LiteralPath $Path -Value $line
}

function Read-CaptureCsv {
    param([string]$Folder, [string]$Name)
    $path = Join-Path $Folder $Name
    if (Test-Path -LiteralPath $path) {
        return @(Import-Csv -LiteralPath $path)
    }
    return @()
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

function Get-ApplicationRestorePlan {
    param([object[]]$Programs)

    foreach ($program in $Programs) {
        $name = [string]$program.DisplayName
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }

        $source = if ($name -match "Microsoft|Office|Teams|Edge|Chrome|Adobe|Reader|VPN|Citrix") {
            "ManagedAppCatalog"
        } else {
            "ManualReview"
        }

        [pscustomobject]@{
            ApplicationName = $name
            Version         = $program.DisplayVersion
            Publisher       = $program.Publisher
            RestoreAction   = if ($source -eq "ManagedAppCatalog") { "Queue install or confirm via endpoint management" } else { "Review with technician or application owner" }
            Source          = $source
        }
    }
}

function Get-PrinterRestorePlan {
    param([object[]]$Printers)

    foreach ($printer in $Printers) {
        [pscustomobject]@{
            PrinterName   = $printer.Name
            DriverName    = $printer.DriverName
            PortName      = $printer.PortName
            RestoreAction = "Create port if missing, add driver if available, add printer, then confirm default"
            IsDefault     = $printer.Default
        }
    }
}

function Get-LocalGroupReviewPlan {
    param([object[]]$GroupRows)

    foreach ($row in $GroupRows) {
        [pscustomobject]@{
            GroupName    = $row.GroupName
            MemberName   = $row.MemberName
            MemberType   = $row.MemberType
            RestoreAction = "Review before copying local membership to replacement device"
        }
    }
}

if (-not (Test-Path -LiteralPath $CapturedStatePath)) {
    throw "Captured state folder was not found: $CapturedStatePath"
}
if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$logPath = Join-Path $OutputDirectory "restore-run-log.txt"
Set-Content -LiteralPath $logPath -Value "New device restore plan started: $(Get-Date -Format "s")"

Write-RunLog -Path $logPath -Message "Reading captured state from $CapturedStatePath."

$programs = Read-CaptureCsv -Folder $CapturedStatePath -Name "installed-programs.csv"
$printers = Read-CaptureCsv -Folder $CapturedStatePath -Name "printers.csv"
$groups = Read-CaptureCsv -Folder $CapturedStatePath -Name "local-group-memberships.csv"
$baseline = Read-CaptureCsv -Folder $CapturedStatePath -Name "computer-baseline.csv" | Select-Object -First 1

$appPlan = @(Get-ApplicationRestorePlan -Programs $programs)
$printerPlan = @(Get-PrinterRestorePlan -Printers $printers)
$groupReview = @(Get-LocalGroupReviewPlan -GroupRows $groups)

$restorePlan = @(
    [pscustomobject]@{
        Step = "RenameComputer"
        Target = $NewComputerName
        Action = "Plan replacement computer name"
        Mode = $Mode
    },
    [pscustomobject]@{
        Step = "Applications"
        Target = $NewComputerName
        Action = "Review application restore plan and queue managed installs where possible"
        Mode = $Mode
    },
    [pscustomobject]@{
        Step = "Printers"
        Target = $NewComputerName
        Action = "Restore printers from captured state where drivers and ports are available"
        Mode = $Mode
    },
    [pscustomobject]@{
        Step = "LocalGroups"
        Target = $NewComputerName
        Action = "Review local group memberships before copying anything"
        Mode = $Mode
    }
)

$restorePlan | Export-Csv -LiteralPath (Join-Path $OutputDirectory "restore-plan.csv") -NoTypeInformation
$appPlan | Export-Csv -LiteralPath (Join-Path $OutputDirectory "application-restore-plan.csv") -NoTypeInformation
$printerPlan | Export-Csv -LiteralPath (Join-Path $OutputDirectory "printer-restore-plan.csv") -NoTypeInformation
$groupReview | Export-Csv -LiteralPath (Join-Path $OutputDirectory "local-group-review-plan.csv") -NoTypeInformation

$summary = [pscustomobject]@{
    NewComputerName       = $NewComputerName
    SourceOldComputerName = $baseline.ComputerName
    TechnicianName        = $TechnicianName
    MigrationBatch        = $MigrationBatch
    Mode                  = $Mode
    ApplicationsReviewed  = $appPlan.Count
    PrintersReviewed      = $printerPlan.Count
    LocalGroupRows        = $groupReview.Count
    CreatedAt             = Get-Date -Format "s"
}
$summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $OutputDirectory "restore-summary.json")

Add-MasterTrackingRow -Path $MasterTrackingCsv -Row ([pscustomobject]@{
    Timestamp               = Get-Date -Format "s"
    Stage                   = "NewDeviceRestore"
    MigrationBatch          = $MigrationBatch
    TechnicianName          = $TechnicianName
    OldComputerName         = $baseline.ComputerName
    ReplacementComputerName = $NewComputerName
    Status                  = "RestorePlanned"
    ProgramCount            = $appPlan.Count
    PrinterCount            = $printerPlan.Count
    LocalGroupRows          = $groupReview.Count
    DeviceFolder            = $CapturedStatePath
})

if ($Mode -eq "SimulateApply") {
    Set-Content -LiteralPath (Join-Path $OutputDirectory "simulated-apply.log") -Value @(
        "Would rename replacement computer to $NewComputerName",
        "Would queue managed application installs where available",
        "Would add printers after confirming ports and drivers",
        "Would review local group membership before applying"
    )
    Write-RunLog -Path $logPath -Message "Simulated apply log written."
}

if ($RestartAfterRestore) {
    Write-RunLog -Path $logPath -Message "Restart requested. Sanitized demo logs the request instead of forcing a restart."
} else {
    Write-RunLog -Path $logPath -Message "Restart skipped."
}

Write-RunLog -Path $logPath -Message "New device restore planning complete."
