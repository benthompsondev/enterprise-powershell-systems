# Enterprise Support And Code Review Utilities

This folder is a sanitized set of smaller PowerShell examples based on practical support and code review work.

Not every useful script turns into a giant system. Some of the work was smaller: checking a DHCP reservation request before another team used it, finding devices affected by a Windows update issue, counting user profiles before cleanup, or exporting security group access for a manager review.

This project is meant to show that side of the work too. I was one of the few active people helping with internal script/code review, so part of my role was reviewing scripts from other teams, tightening them up, and explaining the changes clearly enough that the team could learn from the feedback before using the script.

The public version uses fake data and local output files. It does not include raw workplace scripts, real emails, real hostnames, real users, internal paths, or private system details.

## What This Does

The demo includes four small utilities:

| Script | What it checks |
| --- | --- |
| `New-DhcpReservationReviewDemo.ps1` | Reviews DHCP reservation requests for invalid MAC addresses, duplicate IPs, and IPs outside the expected demo scope |
| `Get-WindowsUpdateRemediationTargetsDemo.ps1` | Reads a device update inventory and writes a report showing which devices need cleanup, reboot, remediation, or no action |
| `Get-EndpointProfileCleanupTargetsDemo.ps1` | Counts real user profiles on endpoints while excluding system, admin, and support profiles, then ranks cleanup targets |
| `Export-SecurityGroupAuditDemo.ps1` | Turns group membership data into a manager-friendly access review export and summary |

There is also a suite runner:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Invoke-SupportUtilitySuiteDemo.ps1
```

## The Problem This Solves

These are the kinds of small problems that come up constantly in IT:

- another team submits a script and needs someone to check if it is safe and clear
- a Windows update issue needs a clean list of devices to fix
- endpoints build up old user profiles and need cleanup candidates
- departments need a CSV showing who has access to a security group
- scripts need comments, validation, and reviewable output before they are used

The value is not only the script. It is the habit around the script: check the input, validate the risky parts, write output another person can understand, and make the next run easier.

## How It Works

Each script reads a fake CSV from `examples\`, validates the rows, and writes reports under `output\`.

The scripts are report-first on purpose. They do not touch Active Directory, DHCP servers, endpoints, or Windows Update. The demo version shows the logic and review output without making live changes.

## Run The Demo

From this folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1
```

Expected result:

```text
Demo check passed.
```

The demo check runs the suite, confirms the expected output files exist, and checks for a few expected review decisions.

## Output Files

The suite writes:

- `output\dhcp-reservation-review.csv`
- `output\windows-update-remediation-targets.csv`
- `output\endpoint-profile-cleanup-targets.csv`
- `output\security-group-audit-export.csv`
- `output\security-group-audit-summary.csv`
- `output\support-utility-suite-summary.csv`

Generated examples are also included in `examples\sample-output\` so the project can be reviewed quickly without running it first.

## What This Shows

- PowerShell CSV automation
- code review thinking
- defensive validation before action
- DHCP reservation review logic
- Windows update troubleshooting reports
- endpoint profile cleanup targeting
- security group access audit exports
- manager-friendly handoff files
- honest authorship framing for reviewed or improved scripts

## What Was Changed For The Demo

The public version uses:

- fake devices
- fake users
- fake groups
- fake ticket IDs
- TEST-NET IP ranges
- local CSV files
- simulated output instead of live system changes

The real email/code review context stays private. This repo only includes sanitized examples of the kind of review and support work involved.
