# Enterprise Support And Code Review Utilities

This folder is about the smaller support scripts and code review work I was doing alongside larger automation projects.

Not every useful PowerShell project is a huge system. Some of the useful work was reviewing another team's script before it was used, writing safer versions, adding logging, explaining risk, or turning an ad hoc request into a CSV report someone else could actually use.

I was often the person reviewing scripts for other technical teams, and at times I was pretty much the only active reviewer. Part of my role was acting as a second set of eyes before a script was used. I would read the request, understand what the script was trying to do, check where it could fail, make the risky parts clearer, and send back practical feedback instead of just saying "approved" or "not approved."

This public version keeps that story without exposing the private details. It uses fake data, local output files, sanitized review examples, and template-style documentation instead of raw emails, internal paths, hostnames, users, or production scripts.

## What This Does

The demo has two parts.

First, it includes four small support utilities:

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

Second, it includes sanitized code review artifacts:

| Document | What it shows |
| --- | --- |
| `docs\code-review-notes.md` | How I approached internal PowerShell/code review requests |
| `docs\code-review-template.md` | A reusable review packet template for script requests |
| `docs\sanitized-review-examples.md` | Sanitized examples based on DHCP, web traffic simulation, and browser update review work |

## The Problem This Solves

These are the kinds of small problems that come up constantly in IT:

- another team submits a script and needs someone to check if it is safe and clear
- a team needs review feedback written in plain English, not just a technical pass/fail
- a Windows update issue needs a clean list of devices to fix
- endpoints build up old user profiles and need cleanup candidates
- departments need a CSV showing who has access to a security group
- scripts need comments, validation, and reviewable output before they are used

The value is not only the script. It is the habit around the script: understand the request, check the risky parts, improve the code where it makes sense, write output another person can understand, and explain the feedback so the owning team learns from it.

## How It Works

Each script reads a fake CSV from `examples\`, validates the rows, and writes reports under `output\`.

The scripts are report-first on purpose. They do not touch Active Directory, DHCP servers, endpoints, or Windows Update. The demo version shows the logic and review output without making live changes.

The review docs are also sanitized on purpose. They show the shape of the review work: purpose, risk, systems touched, findings, suggested changes, testing notes, and a plain-English response back to the requesting team.

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
- reviewing scripts written by other technical teams
- explaining risk without overcomplicating it
- turning review feedback into cleaner code, comments, and run notes
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

## What I Would Point Out

The main point I would point out is not "I wrote four small scripts." It is that I was trusted to review and improve scripts before other teams used them.

For these kinds of reviews, I usually looked for:

- hard-coded values that should be parameters
- places where the script could affect the wrong system or scope
- missing validation around CSV input, IPs, MAC addresses, paths, or targets
- no logging or unclear output
- scripts that worked for the author but would be hard for another team to run safely
- places where a short comment or usage note would prevent mistakes later

That is the part I wanted this project to show: practical review judgment, not just PowerShell syntax.

## What This Says About My Work

This folder shows the team-support side of my work.

I was not only writing my own scripts. I was helping other technical teams make their scripts safer, clearer, and easier to test. That meant looking for missing validation, unclear risk, hard-coded values, weak logging, confusing output, or missing run instructions.

I like this kind of work because it improves more than one script. If the feedback is clear, the next script that team writes is usually better too.
