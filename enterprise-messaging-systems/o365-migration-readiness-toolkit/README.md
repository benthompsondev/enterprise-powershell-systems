# O365 Migration Support Toolkit

This is a sanitized PowerShell toolkit based on scripts I wrote while helping move a large on-prem Exchange environment to O365.

The real project was not one clean cutover. It ran in stages and had a lot of moving parts: thousands of users, hundreds of shared mailboxes, public folders, licensing groups, workstation setup, phones, support calls, and mailbox issues that showed up only after a migration wave started.

My scripts were separate for a reason. Each one solved a different problem that kept coming up during the move from on-prem mail to O365:

- figure out which users were already migrated and which still needed work
- add or check license-backed AD groups before users moved
- find duplicate license paths so extra licensing could be cleaned up
- check whether shared mailboxes were safe to migrate
- remove or plan public folder permissions before folders were archived or converted
- repair mailbox states such as soft-deleted or conflicting mailboxes
- create CSV reports so the migration team did not have to manually check every account

This public version uses fake data and local reports instead of touching Exchange, Active Directory, or Microsoft 365.

## What This Does

The demo is split into separate scripts, because the real work was split that way too.

| Script | Problem it solves |
| --- | --- |
| `Export-UserMigrationWavePlanDemo.ps1` | Figures out which users are already migrated, which users are ready for the next wave, and which users need data cleanup first |
| `New-O365LicenseGroupPlanDemo.ps1` | Checks license-backed AD groups, plans missing group assignments, and flags duplicate license paths |
| `Test-SharedMailboxMigrationReadinessDemo.ps1` | Checks shared mailbox permissions and blocks mailbox migration until every delegated user is ready |
| `New-PublicFolderRetirementPlanDemo.ps1` | Plans public folder archive, conversion, owner review, and permission cleanup work |
| `New-MailboxIssueRepairPlanDemo.ps1` | Builds repair plans for soft-deleted mailboxes, disabled accounts with mailbox state, and duplicate license issues |
| `Invoke-O365MigrationSuiteDemo.ps1` | Runs the separate scripts together and writes a suite-level summary |

The main idea is still simple: check the data first, write clear reports, and avoid moving mailboxes or changing licenses when the source data says something is not ready.

## The Problem This Solved

During a staged email migration, not everyone moves to the cloud platform at the same time. That creates a lot of awkward edge cases.

One example: a shared mailbox might look ready until you check every user who has access to it. If even one delegated user is still on-prem, migrating the shared mailbox too early can break access and create support tickets.

The same kind of thing happened with user migrations, licensing, public folders, and mailbox repair work. Some users needed the right license-backed directory group before they could fully use O365. Some accounts picked up duplicate license paths. Some public folders had to be archived, while active ones had to be converted or reviewed. Soft-deleted mailbox issues also showed up and needed a repeatable repair path.

The scripts helped turn a long manual project into separate repeatable checks:

```text
user exports -> migration wave plan -> license group plan -> shared mailbox readiness -> public folder cleanup -> mailbox repair plan
```

## What It Handles

### User Migration Waves

The user migration script answers the basic questions the project team kept needing:

- who is already migrated
- who is ready for the next migration wave
- who still needs license group work
- who should be held because the account is disabled or missing data
- which rows need someone to review before action

### License Group Work

Licensing was tied to AD groups. The license script checks whether the user has the expected license-backed group, plans missing group work, and flags duplicate license paths so extra licensing can be removed.

### Shared Mailbox Migration

Shared mailboxes were a separate problem. A shared mailbox could only safely move once every delegated user was already migrated and licensed. The shared mailbox script checks all mailbox delegates and writes a ready or blocked report with the exact blocker.

### Public Folder Retirement

Public folders did not fit the target O365 setup the same way. The public folder script builds a plan for archive, conversion to shared mailbox, owner review, and permission removal.

### Mailbox Repair Work

Mailbox repair was another separate lane. The demo includes soft-deleted mailbox repair planning, disabled-account review, and duplicate-license cleanup. These were the kinds of issues that showed up after real batches started moving.

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

The suite writes separate folders under `output\`:

- `01-user-migration-wave\user-migration-wave-plan.csv`
- `01-user-migration-wave\migration-data-gap-report.csv`
- `02-license-groups\user-license-group-plan.csv`
- `02-license-groups\duplicate-license-review.csv`
- `03-shared-mailboxes\shared-mailbox-migration-readiness.csv`
- `03-shared-mailboxes\shared-mailbox-permission-detail.csv`
- `04-public-folders\public-folder-retirement-plan.csv`
- `05-mailbox-repair\mailbox-issue-repair-plan.csv`
- `migration-suite-summary.csv`
- `run-log.txt`

These are the kinds of files another admin or migration lead can review before making real changes. The project is report-first on purpose.

Generated examples are included under `examples\sample-output\` so the project can be reviewed quickly without running the demo first.

## What This Shows

- PowerShell automation for Exchange/O365-style migrations
- staged user migration planning
- CSV-driven reporting
- shared mailbox permission and delegate review
- license-backed AD group validation
- duplicate license cleanup
- public folder archive/conversion/permission cleanup planning
- soft-deleted mailbox issue handling
- separate scripts for separate migration problems
- review-first output before action
- fake data and local files for safe sharing

## What This Says About My Work

This toolkit is probably the best example here of one big project being broken into smaller repeatable checks.

The real work was not just "move mailboxes." It was figuring out who was ready, who was blocked, which shared mailboxes depended on users who had not moved yet, where license groups were missing or duplicated, what to do with public folders, and how to handle mailbox issues that kept coming back.

I built separate scripts because the problems were separate. That made the output easier to trust, easier to explain, and easier for the project team to use during a long staged migration.

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
