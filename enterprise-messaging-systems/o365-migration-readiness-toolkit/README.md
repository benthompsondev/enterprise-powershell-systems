# O365 Migration Readiness Toolkit

This is a sanitized PowerShell toolkit based on scripts I wrote while helping move a large on-prem Exchange environment to O365.

The real project was not one clean cutover. Users moved in batches, shared mailboxes could only move after their delegated users were ready, public folders had to be cleaned up or replaced, licensing had to be checked, and random mailbox issues had to be fixed as they came up.

This demo keeps that workflow shape, but it uses fake data and writes reports instead of touching Exchange, Active Directory, or Microsoft 365.

## What This Does

`scripts\Invoke-O365MigrationReadinessDemo.ps1` reads fake migration CSVs and creates a review package for:

- shared mailbox migration readiness
- delegated user migration blockers
- O365 license group readiness
- duplicate license path cleanup
- public folder retirement or conversion planning
- soft-deleted mailbox repair planning
- summary counts for a migration lead or support team

The main idea is simple: do the checks first, write clear output, and avoid moving a mailbox or changing licensing when the data still says something is not ready.

## The Problem This Solved

During a staged email migration, not everyone is on the cloud platform at the same time. That creates a lot of awkward edge cases.

For example, a shared mailbox might look ready until you check the users who have access to it. If even one delegated user is still on-prem, migrating the shared mailbox too early can create support tickets and broken access.

The same thing happened with licensing and public folders. Some users needed the right license-backed directory group before they could fully use O365. Some accounts picked up duplicate license paths. Public folders had to be retired, archived, or converted to shared mailboxes because they did not fit the target cloud setup.

The scripts helped turn that into a repeatable checklist:

```text
fake migration exports -> readiness checks -> blocked/ready reports -> cleanup plans -> summary package
```

## What It Handles

### Shared Mailbox Readiness

The demo checks every user listed with access to a shared mailbox.

It marks a shared mailbox as ready only when all delegated users are already migrated. If a user is still on-prem, missing from the migration data, or not fully licensed, the mailbox is marked as blocked with a reason.

### License Group Readiness

The demo checks whether users have the expected license-backed group. It also flags users with multiple license paths so an admin can clean up extra licensing before it becomes waste.

### Public Folder Cleanup

The demo builds a review plan for public folders. Some folders are marked for archive, some for shared mailbox conversion, and some for permission removal.

### Soft-Deleted Mailbox Issues

The demo includes soft-deleted mailbox repair planning. In real migrations, these edge cases show up at the worst time, so I wanted the public version to show that kind of troubleshooting path too.

## Run The Demo

From this folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1
```

Expected result:

```text
Demo check passed.
```

The test runs the toolkit against fake CSVs and confirms the expected reports are created.

## Output Files

The script writes:

- `shared-mailbox-readiness.csv`
- `shared-mailbox-permission-detail.csv`
- `user-license-readiness.csv`
- `duplicate-license-review.csv`
- `public-folder-cleanup-plan.csv`
- `mailbox-issue-repair-plan.csv`
- `migration-readiness-summary.csv`
- `run-log.txt`

These are the kinds of files another admin or migration lead can review before making real changes.

Generated examples are included under `examples\sample-output\` so the project can be reviewed quickly without running the demo first.

## What This Shows

- PowerShell automation for Exchange/O365-style migrations
- staged migration readiness checks
- CSV-driven reporting
- shared mailbox permission review
- licensing group validation
- duplicate license cleanup
- public folder retirement planning
- soft-deleted mailbox issue handling
- review-first output before action
- fake data and local files for safe sharing

## Public Safety

This is not a raw workplace script.

The public version removes or replaces:

- employer names
- real users
- real mailbox names
- real domains
- tenant details
- real group names
- internal server names
- production exports
- internal paths
- credentials or session details

The demo uses fake `example.local` data and local output folders.
