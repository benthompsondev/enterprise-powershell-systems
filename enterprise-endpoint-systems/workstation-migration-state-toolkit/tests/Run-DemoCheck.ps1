$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$OutputRoot = Join-Path $ProjectRoot "output-test"
$MockData = Join-Path $OutputRoot "mock-old-device"
$StateRoot = Join-Path $OutputRoot "device-state"
$RestoreRoot = Join-Path $OutputRoot "restore"
$DirectoryRoot = Join-Path $OutputRoot "directory"
$MasterTracking = Join-Path $OutputRoot "migration-master-tracking.csv"

$CaptureScript = Join-Path $ProjectRoot "scripts\Export-OldDeviceStateDemo.ps1"
$RestoreScript = Join-Path $ProjectRoot "scripts\Restore-NewDeviceStateDemo.ps1"
$DirectoryScript = Join-Path $ProjectRoot "scripts\Invoke-DirectoryComputerMigrationDemo.ps1"

try {
    if (Test-Path -LiteralPath $OutputRoot) {
        Remove-Item -LiteralPath $OutputRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $MockData -Force | Out-Null

    @(
        [pscustomobject]@{ DisplayName = "Microsoft 365 Apps"; DisplayVersion = "16.0"; Publisher = "Microsoft"; InstallDate = "20260101" }
        [pscustomobject]@{ DisplayName = "Adobe Reader"; DisplayVersion = "24.1"; Publisher = "Adobe"; InstallDate = "20260201" }
        [pscustomobject]@{ DisplayName = "Specialized Clinical Viewer Demo"; DisplayVersion = "5.2"; Publisher = "Example Vendor"; InstallDate = "20260301" }
    ) | Export-Csv -LiteralPath (Join-Path $MockData "installed-programs.csv") -NoTypeInformation

    @(
        [pscustomobject]@{ Name = "Nursing Station Printer"; DriverName = "Universal Print Driver"; PortName = "IP_10_0_0_50"; Shared = "False"; Type = "Local"; Default = "True" }
        [pscustomobject]@{ Name = "Registration Label Printer"; DriverName = "Label Printer Driver"; PortName = "IP_10_0_0_51"; Shared = "False"; Type = "Local"; Default = "False" }
    ) | Export-Csv -LiteralPath (Join-Path $MockData "printers.csv") -NoTypeInformation

    @(
        [pscustomobject]@{ GroupName = "Remote Desktop Users"; MemberName = "EXAMPLE\SupportTechs"; MemberType = "Group"; Source = "LocalGroup" }
        [pscustomobject]@{ GroupName = "Administrators"; MemberName = "EXAMPLE\DesktopAdmins"; MemberType = "Group"; Source = "LocalGroup" }
    ) | Export-Csv -LiteralPath (Join-Path $MockData "local-groups.csv") -NoTypeInformation

    $mockDirectoryCsv = Join-Path $OutputRoot "mock-directory-computers.csv"
    @(
        [pscustomobject]@{ ComputerName = "OLD-WIN10-042"; OU = "OU=ClinicalWorkstations,OU=Computers,DC=example,DC=local"; Groups = "APP-ClinicalViewer;APP-LabelPrinting;POL-Win11-Ready" }
        [pscustomobject]@{ ComputerName = "NEW-WIN11-042"; OU = "OU=Staging,OU=Computers,DC=example,DC=local"; Groups = "POL-Win11-Ready" }
    ) | Export-Csv -LiteralPath $mockDirectoryCsv -NoTypeInformation

    powershell -ExecutionPolicy Bypass -File $CaptureScript `
        -OldComputerName "OLD-WIN10-042" `
        -ReplacementComputerName "NEW-WIN11-042" `
        -TechnicianName "contractor.demo" `
        -StateRootPath $StateRoot `
        -MasterTrackingCsv $MasterTracking `
        -MockDataDirectory $MockData

    $deviceFolder = Join-Path $StateRoot "OLD-WIN10-042_to_NEW-WIN11-042"
    foreach ($file in @("installed-programs.csv", "printers.csv", "local-group-memberships.csv", "computer-baseline.csv", "migration-manifest.json", "capture-run-log.txt")) {
        if (-not (Test-Path -LiteralPath (Join-Path $deviceFolder $file))) {
            throw "Capture output missing: $file"
        }
    }

    powershell -ExecutionPolicy Bypass -File $RestoreScript `
        -NewComputerName "NEW-WIN11-042" `
        -CapturedStatePath $deviceFolder `
        -TechnicianName "contractor.demo" `
        -OutputDirectory $RestoreRoot `
        -MasterTrackingCsv $MasterTracking `
        -Mode SimulateApply

    foreach ($file in @("restore-plan.csv", "application-restore-plan.csv", "printer-restore-plan.csv", "local-group-review-plan.csv", "restore-summary.json", "simulated-apply.log")) {
        if (-not (Test-Path -LiteralPath (Join-Path $RestoreRoot $file))) {
            throw "Restore output missing: $file"
        }
    }

    $printerPlan = Import-Csv -LiteralPath (Join-Path $RestoreRoot "printer-restore-plan.csv")
    if ($printerPlan.Count -ne 2 -or -not ($printerPlan.RestoreAction -match "Create port")) {
        throw "Expected printer restore plan to include two printers and port/driver actions"
    }

    $appPlan = Import-Csv -LiteralPath (Join-Path $RestoreRoot "application-restore-plan.csv")
    if (-not ($appPlan.Source -contains "ManagedAppCatalog") -or -not ($appPlan.Source -contains "ManualReview")) {
        throw "Expected app plan to separate managed catalog apps from manual review apps"
    }

    powershell -ExecutionPolicy Bypass -File $DirectoryScript `
        -OldComputerName "OLD-WIN10-042" `
        -NewComputerName "NEW-WIN11-042" `
        -MockDirectoryCsv $mockDirectoryCsv `
        -OutputDirectory $DirectoryRoot `
        -MasterTrackingCsv $MasterTracking `
        -Mode SimulateApply

    $directoryPlan = Import-Csv -LiteralPath (Join-Path $DirectoryRoot "directory-migration-plan.csv")
    if (-not ($directoryPlan.ActionType -contains "MoveComputerObject")) {
        throw "Expected directory plan to include OU move"
    }
    if ((@($directoryPlan | Where-Object { $_.ActionType -eq "AddGroupMembership" })).Count -lt 2) {
        throw "Expected directory plan to include missing group memberships"
    }

    $tracking = Import-Csv -LiteralPath $MasterTracking
    if ($tracking.Count -ne 3) {
        throw "Expected three master tracking rows, found $($tracking.Count)"
    }
    if (-not ($tracking.Stage -contains "OldDeviceCapture") -or -not ($tracking.Stage -contains "NewDeviceRestore") -or -not ($tracking.Stage -contains "DirectoryComputerPrep")) {
        throw "Expected tracking to include all three workflow stages"
    }

    Write-Output "Demo check passed."
}
finally {
    if (Test-Path -LiteralPath $OutputRoot) {
        Remove-Item -LiteralPath $OutputRoot -Recurse -Force
    }
}
