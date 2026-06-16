# Workstation Migration State Toolkit

This is a sanitized three-script PowerShell toolkit for Windows workstation replacement projects.

The real workflow was built for a large Windows 10 to Windows 11 hardware refresh where many devices needed to be replaced quickly and consistently. The goal was to make the process simple enough for external technicians to follow while still giving IT the tracking, logs, and review points needed to keep the migration under control.

The useful idea is not flashy: capture the old device, restore what can be restored on the new device, then let IT handle the directory cleanup with a reviewable plan.

## What The System Does

### 1. Old Device Capture

`scripts/Export-OldDeviceStateDemo.ps1`

Run on the old workstation before replacement. It creates a per-device folder containing:

- installed program inventory
- printer inventory
- local group membership inventory
- computer baseline CSV
- migration manifest JSON
- run log

It also appends a row to a master tracking CSV. That tracking file is important because it gives the migration lead a simple way to see which devices were completed, who ran the script, and how much work was moving each day.

### 2. New Device Restore Planning

`scripts/Restore-NewDeviceStateDemo.ps1`

Run against the captured old-device folder after the new workstation is ready. It reads the captured CSVs and writes:

- restore plan
- application restore plan
- printer restore plan
- local group review plan
- restore summary JSON
- simulated apply log

In a real environment, this is where managed software deployment, printer restore, default printer handling, and restart behavior would be coordinated. The public version keeps that structure but writes plans instead of changing a real machine.

### 3. IT Directory Prep

`scripts/Invoke-DirectoryComputerMigrationDemo.ps1`

Run by IT after the endpoint work. It uses mock directory data to plan:

- moving the replacement computer to the old computer's OU pattern
- copying missing computer group memberships from old device to new device
- leaving reviewable CSV/JSON output before anything would be applied

The public demo uses fake directory data instead of Active Directory.

## Why This Was Useful

The original system supported a high-volume workstation replacement effort. External technicians did not need deep IT experience. They could replace hardware, run the old-device script, run the new-device script, and let IT handle the directory-side work.

That saved time because the process was repeatable:

```text
old device capture -> new device restore plan -> IT directory prep -> master tracking
```

It also made progress visible. The master tracking CSV could be used to see how many devices were completed, which technician completed them, and where the process was slowing down.

## Run The Demo

From this folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1
```

Expected result:

```text
Demo check passed.
```

The test creates fake old-device data, runs all three scripts, and checks that the expected CSV, JSON, log, restore, and directory planning files are created.

## What This Shows

- endpoint migration automation
- Windows workstation inventory
- installed program capture
- printer capture and restore planning
- local group membership review
- master CSV tracking across many devices
- contractor-friendly scripts with IT review points
- directory group and OU migration planning
- safe simulation instead of direct public Active Directory changes
- logging, manifests, and per-device evidence folders

## Public Safety

This is not a raw workplace script.

The public version removes or generalizes:

- employer names
- internal domains
- real device names
- real technician names
- real printer names
- internal OU paths
- production group names
- file shares
- logs from real migrations

The demo uses fake names, fake directory data, and local output folders.
