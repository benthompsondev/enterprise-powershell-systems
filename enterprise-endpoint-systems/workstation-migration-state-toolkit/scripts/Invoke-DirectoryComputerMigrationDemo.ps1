<#
.SYNOPSIS
Plans directory cleanup for a replacement workstation.

.DESCRIPTION
This sanitized demo mirrors the IT-owned part of a workstation migration. After
contractors capture and restore endpoint state, IT can plan the directory work:
copy group memberships from old computer to new computer, move the new computer
to the matching OU, and write reviewable output.

The public version uses a mock directory CSV instead of Active Directory.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$OldComputerName,

    [Parameter(Mandatory)]
    [string]$NewComputerName,

    [Parameter(Mandatory)]
    [string]$MockDirectoryCsv,

    [string]$OutputDirectory = ".\output\directory",
    [string]$MasterTrackingCsv = ".\output\migration-master-tracking.csv",
    [ValidateSet("PlanOnly", "SimulateApply")]
    [string]$Mode = "PlanOnly"
)

$ErrorActionPreference = "Stop"

function Write-RunLog {
    param([string]$Path, [string]$Message)
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Write-Output $line
    Add-Content -LiteralPath $Path -Value $line
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

if (-not (Test-Path -LiteralPath $MockDirectoryCsv)) {
    throw "Mock directory CSV was not found: $MockDirectoryCsv"
}
if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$logPath = Join-Path $OutputDirectory "directory-migration-run-log.txt"
Set-Content -LiteralPath $logPath -Value "Directory migration plan started: $(Get-Date -Format "s")"

$directory = Import-Csv -LiteralPath $MockDirectoryCsv
$oldComputer = $directory | Where-Object { $_.ComputerName -eq $OldComputerName } | Select-Object -First 1
$newComputer = $directory | Where-Object { $_.ComputerName -eq $NewComputerName } | Select-Object -First 1

if ($null -eq $oldComputer) {
    throw "Old computer was not found in mock directory data: $OldComputerName"
}
if ($null -eq $newComputer) {
    throw "New computer was not found in mock directory data: $NewComputerName"
}

Write-RunLog -Path $logPath -Message "Planning directory migration from $OldComputerName to $NewComputerName."

$oldGroups = @([string]$oldComputer.Groups -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() })
$newGroups = @([string]$newComputer.Groups -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() })
$groupsToAdd = @($oldGroups | Where-Object { $newGroups -notcontains $_ })

$planRows = New-Object System.Collections.Generic.List[object]

$planRows.Add([pscustomobject]@{
    ActionType     = "MoveComputerObject"
    SourceComputer = $OldComputerName
    TargetComputer = $NewComputerName
    CurrentValue   = $newComputer.OU
    PlannedValue   = $oldComputer.OU
    Notes          = "Move replacement computer to the same OU pattern as the old device"
})

foreach ($group in $groupsToAdd) {
    $planRows.Add([pscustomobject]@{
        ActionType     = "AddGroupMembership"
        SourceComputer = $OldComputerName
        TargetComputer = $NewComputerName
        CurrentValue   = ""
        PlannedValue   = $group
        Notes          = "Copy computer group membership from old device to replacement device"
    })
}

if ($groupsToAdd.Count -eq 0) {
    $planRows.Add([pscustomobject]@{
        ActionType     = "GroupMembershipReview"
        SourceComputer = $OldComputerName
        TargetComputer = $NewComputerName
        CurrentValue   = "AlreadyAligned"
        PlannedValue   = ""
        Notes          = "Replacement computer already has the same mock group set"
    })
}

$planCsv = Join-Path $OutputDirectory "directory-migration-plan.csv"
$planJson = Join-Path $OutputDirectory "directory-migration-plan.json"
$planRows | Export-Csv -LiteralPath $planCsv -NoTypeInformation
$planRows | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $planJson

if ($Mode -eq "SimulateApply") {
    Set-Content -LiteralPath (Join-Path $OutputDirectory "simulated-directory-apply.log") -Value @(
        "Would move $NewComputerName to OU: $($oldComputer.OU)",
        "Would add $($groupsToAdd.Count) missing computer group membership(s)",
        "Would leave old computer object unchanged until migration review is complete"
    )
}

Add-MasterTrackingRow -Path $MasterTrackingCsv -Row ([pscustomobject]@{
    Timestamp               = Get-Date -Format "s"
    Stage                   = "DirectoryComputerPrep"
    MigrationBatch          = "Win11-Refresh-Demo"
    TechnicianName          = "IT"
    OldComputerName         = $OldComputerName
    ReplacementComputerName = $NewComputerName
    Status                  = "DirectoryPlanCreated"
    ProgramCount            = ""
    PrinterCount            = ""
    LocalGroupRows          = ""
    DeviceFolder            = $OutputDirectory
})

Write-RunLog -Path $logPath -Message "Directory migration plan written to $planCsv."
