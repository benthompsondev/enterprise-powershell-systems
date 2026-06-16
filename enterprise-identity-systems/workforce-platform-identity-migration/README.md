# Workforce Platform Identity Migration Toolkit

This is a sanitized PowerShell toolkit based on an identity cleanup and migration workflow for a Workday-style HR/payroll platform rollout.

Workday is an enterprise platform used for HR, workforce, payroll, finance, and employee data workflows. In a migration like that, directory data matters. If the wrong accounts are created, re-enabled, disabled, licensed, or missing mailbox access, the downstream project can get messy fast.

The real work behind this demo started with imperfect project CSVs. The source data changed over time, some users already existed, some were disabled, some needed new accounts, some needed mailbox/licensing later, and some needed manual review because the script could not safely know the business context.

## What This Toolkit Does

### 1. Validate Source Data

`scripts/Test-WorkforceSourceDataDemo.ps1`

Reads a workforce/project CSV and checks it against mock directory data.

It matches in a careful order:

- employee ID
- professional/license ID
- username
- display name

Then it writes:

- validation report
- validation summary
- run log

The important part is that disabled accounts and duplicate/ambiguous matches are not treated as simple success cases. They are flagged for review.

### 2. Build An Account Action Plan

`scripts/New-WorkforceAccountActionPlanDemo.ps1`

Takes the validation output and creates a reviewable plan for:

- new account creation
- re-enabling existing disabled accounts
- moving accounts into a project OU
- setting workforce attributes
- assigning default groups
- separating manual review rows

The public version writes a plan instead of touching Active Directory.

### 3. Review Accounts In The Project OU

`scripts/Export-ProjectOuReviewDemo.ps1`

Exports accounts currently in the project OU and turns that into a project update package. In the real workflow, this was the recurring reporting piece: after accounts were created, re-enabled, moved, licensed, or reviewed, the project team needed fresh CSVs and logs showing where the account work stood.

The report includes:

- account enabled/disabled state
- whether the account was processed by the migration automation
- which project batch/wave it came from
- what action was taken or planned
- mailbox and license readiness
- group count and review category
- go-live readiness flag

It also flags accounts that may need review, such as:

- disabled accounts still in the project OU
- accounts with very low group counts
- accounts with recent login activity but a termination marker

This mirrors the kind of follow-up script that becomes necessary when a large project dataset is not fully clean. It gave the project team updated CSVs they could use for tracking, cleanup, go-live readiness, and follow-up conversations without manually checking every account.

### 4. Plan Mailbox, License, And Termination Work

`scripts/New-MailboxLicenseActionPlanDemo.ps1`

Takes an approved action list and creates a plan for:

- enabling mailbox access
- assigning license groups
- disabling accounts
- moving terminated users to a terminated OU

Again, the public version writes reviewable output instead of changing live systems.

## The Problem This Solved

The project team needed directory accounts aligned for a workforce/payroll platform migration. The input data was not clean enough to blindly process.

The scripts helped turn that into a safer workflow:

```text
messy project CSV -> validation -> account action plan -> OU review -> mailbox/license/termination plan
```

This mattered because the account work affected people, payroll/workforce workflows, and downstream project tracking. The scripts could process the data quickly, but they also made the limits clear: automation can match and report, but it cannot always know whether a disabled account was disabled for a valid business reason.

The recurring OU review/reporting step was a big part of the value. After each run, updated CSVs and logs could show which accounts had been created, re-enabled, aligned to the project OU, still needed mailbox/licensing work, or needed manual review before go-live.

## Run The Demo

From this folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1
```

Expected result:

```text
Demo check passed.
```

The test uses fake data only. It runs validation, account planning, project OU review, and mailbox/license planning.

## What This Shows

- CSV-driven identity automation
- messy source-data validation
- matching by employee ID, professional ID, username, and display name
- disabled-account handling
- duplicate/ambiguous match review
- account creation planning
- re-enable and move-to-OU planning
- HR/workforce attribute planning
- mailbox and license planning
- termination review planning
- recurring project OU exports for tracking and go-live readiness
- clear reports before changes
- safe mock data instead of real directory writes

## Public Safety

This is not a raw workplace script.

The public version removes or replaces:

- employer names
- real employee names
- real emails
- real domains
- internal OU paths
- production group names
- mailbox routing domains
- tenant or licensing details
- real project reports
- temporary password lists

The demo uses fake `example.local` data and local output folders.
