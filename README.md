# Enterprise PowerShell Systems

[![PowerShell demo checks](https://github.com/benthompsondev/enterprise-powershell-systems/actions/workflows/powershell-demo-check.yml/badge.svg)](https://github.com/benthompsondev/enterprise-powershell-systems/actions/workflows/powershell-demo-check.yml)
[![PowerShell quality checks](https://github.com/benthompsondev/enterprise-powershell-systems/actions/workflows/powershell-quality.yml/badge.svg)](https://github.com/benthompsondev/enterprise-powershell-systems/actions/workflows/powershell-quality.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

This is my main PowerShell portfolio repo.

The projects here are sanitized versions of real systems, scripts, fixes, and review workflows I worked on in a large multi-organization healthcare IT environment. The private details are removed, but the shape of the work is kept: messy CSVs, account and access planning, Microsoft 365 / Exchange migration support, endpoint migrations, reporting, validation, logs, and output another admin can review.

The bigger story is not "I wrote a few scripts." It is that I was turning repeated operational problems into safer, repeatable workflows. Some of that meant building automation myself. Some of it meant reviewing scripts for other technical teams, tightening the risky parts, and helping them improve their testing and run notes before the scripts were used.

These are public-safe demos. They use fake data, local files, and simulated actions instead of raw workplace scripts, real users, private system names, internal paths, or production exports.

Everything here is MIT licensed. The scripts are meant to be useful skeletons for other admins, but they should be reviewed and adapted before being used against live systems.

## Start Here

If you are reviewing this quickly, open these in order:

1. [Script Index](docs/script-index.md) - the fastest map of every script and what it does.
2. [Repo Reviewer Guide](docs/reviewer-guide.md) - the short guide for what to look at first and what each system is meant to prove.
3. [Learner Onboarding Automation](enterprise-healthcare-systems/learner-onboarding-automation/) - the most complete account/access workflow.
4. [Password Remediation Workflow](enterprise-healthcare-systems/password-remediation-workflow/) - a monthly security follow-up system with state tracking.
5. [Workstation Migration State Toolkit](enterprise-endpoint-systems/workstation-migration-state-toolkit/) - a hardware refresh workflow built for hundreds of device replacements.
6. [O365 Migration Support Toolkit](enterprise-messaging-systems/o365-migration-readiness-toolkit/) - migration readiness checks for users, shared mailboxes, public folders, licensing, and mailbox repair.
7. [Workforce Platform Identity Migration Toolkit](enterprise-identity-systems/workforce-platform-identity-migration/) - identity and account planning for a 1000+ user workforce platform rollout.
8. [Browser Bookmark Migration Utility](enterprise-endpoint-systems/browser-bookmark-migration/) - a focused endpoint migration script built around avoiding user pain.
9. [Enterprise Support And Code Review Utilities](enterprise-support-systems/enterprise-support-and-code-review-utilities/) - smaller support scripts plus sanitized examples of the code review work I did for other teams.
10. [Public Release Checklist](docs/public-release-checklist.md) - the privacy and quality checklist I use before publishing another sanitized demo.

The fastest proof that the repo works is the green GitHub Actions badge above. The fastest local check is:

```powershell
powershell -ExecutionPolicy Bypass -File .\enterprise-healthcare-systems\learner-onboarding-automation\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-healthcare-systems\password-remediation-workflow\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-identity-systems\workforce-platform-identity-migration\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-endpoint-systems\browser-bookmark-migration\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-endpoint-systems\workstation-migration-state-toolkit\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-messaging-systems\o365-migration-readiness-toolkit\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-support-systems\enterprise-support-and-code-review-utilities\tests\Run-DemoCheck.ps1
```

## What This Repo Is For

I work in healthcare IT and information systems. A lot of useful automation starts with a messy export, a manual checklist, and a process that needs to be safer and easier to repeat.

These are not raw workplace scripts. They are cleaned demo versions that keep the useful architecture while replacing private systems, paths, domains, users, tickets, and organization details with fake data.

The pattern I want to show is simple:

- validate input before planning changes
- separate planning from execution
- produce reviewable reports and handoff files
- handle duplicate rows, missing values, existing accounts, and unclear flags
- keep logs and demo checks so the workflow can be trusted

## The Through Line

Across the repo, I am trying to show the same working style:

- start with the real operational problem, not a perfect toy example
- treat source data as messy until the script proves otherwise
- plan and report before changing anything risky
- make outputs clear enough for another admin or project team to review
- build guardrails around account, mailbox, endpoint, and security work
- keep fake/demo data public-safe without flattening the workflow into a tiny script
- use GitHub Actions and local demo checks so the repo is more than static documentation
- explain review feedback in normal language when helping other teams improve scripts

## Current Systems

| Status | Project | What It Shows |
| --- | --- | --- |
| Core workflow | [Learner Onboarding Automation](enterprise-healthcare-systems/learner-onboarding-automation/) | Scheduled CSV ingest, source backup, account lifecycle planning, AD-style matching, Exchange/mailbox planning, group membership, upstream response exports, ServiceNow-style handoff, notification drafts, reports, and validation |
| Core workflow | [Password Remediation Workflow](enterprise-healthcare-systems/password-remediation-workflow/) | Monthly security export conversion, stateful remediation cycles, mock directory checks, staged notifications, duplicate-run protection, audit output, and safe final reset planning |
| Identity automation | [Workforce Platform Identity Migration Toolkit](enterprise-identity-systems/workforce-platform-identity-migration/) | Workday-style source validation, account creation/re-enable planning, project OU review, mailbox/license planning, termination review, and fake data reports |
| Endpoint automation | [Browser Bookmark Migration Utility](enterprise-endpoint-systems/browser-bookmark-migration/) | Chrome-to-Edge bookmark migration, multi-user profile discovery, HTML backups, recursive bookmark handling, Edge merge without overwriting existing favorites, reporting, and a manual recovery path |
| Endpoint automation | [Workstation Migration State Toolkit](enterprise-endpoint-systems/workstation-migration-state-toolkit/) | Old-device capture, new-device restore planning, printer/app/local group inventory, master tracking CSV, per-device evidence folders, and directory group/OU migration planning |
| Messaging migration | [O365 Migration Support Toolkit](enterprise-messaging-systems/o365-migration-readiness-toolkit/) | On-prem Exchange to O365 user migration planning across thousands of users, shared mailbox migration gating, license group review, duplicate license cleanup, public folder archive/conversion planning, soft-deleted mailbox repair planning, and migration summary reports |
| Support and review | [Enterprise Support And Code Review Utilities](enterprise-support-systems/enterprise-support-and-code-review-utilities/) | Smaller support scripts plus sanitized code review packets for DHCP reservation review, web traffic simulation review, scheduled browser update review, Windows update troubleshooting, endpoint cleanup targeting, and security group audit exports |

## What This Shows

These projects are meant to show how I think through operations automation:

- take a messy input file seriously
- validate before planning
- separate planning from action
- write output another admin can review
- keep logs and sample reports
- use fake data so the workflow can be shared safely
- add demo checks so the repo is not just a folder of scripts

It also shows a side of my work that is easy to miss from script names alone: I was often the person reviewing scripts for other technical teams. I helped turn "this script works on my machine" into something safer to run, easier to test, and easier for another team to understand.

## Quick Verification

Run the demo checks from the repo root:

```powershell
Set-Location .\enterprise-healthcare-systems\learner-onboarding-automation
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1

Set-Location ..\password-remediation-workflow
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1

Set-Location ..\..\enterprise-identity-systems\workforce-platform-identity-migration
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1

Set-Location ..\..\enterprise-endpoint-systems\browser-bookmark-migration
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1

Set-Location ..\workstation-migration-state-toolkit
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1

Set-Location ..\..\enterprise-messaging-systems\o365-migration-readiness-toolkit
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1

Set-Location ..\..\enterprise-support-systems\enterprise-support-and-code-review-utilities
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1
```

Expected result:

```text
Demo check passed.
```

## Resume Alignment

These projects connect to the kind of work I have done around:

- PowerShell automation
- Active Directory and hybrid identity workflows
- Microsoft 365, Exchange Online, Teams, SharePoint, and OneDrive support
- Azure AD / Entra ID troubleshooting
- SCCM, Intune, Windows deployment, and endpoint support
- healthcare IT operations
- technical documentation and repeatable process design

## Privacy And Safety

No raw workplace scripts are published here.

These examples use:

- fake users
- fake groups
- fake domains
- fake tickets
- fake CSV exports
- local mock data
- simulation output instead of real system changes

Do not add real employer names, internal domains, hostnames, usernames, email addresses, ticket data, credentials, tenant IDs, client IDs, network shares, production logs, or screenshots to this repo.

See [SECURITY.md](SECURITY.md) and [Public Release Checklist](docs/public-release-checklist.md) for the safety rules I use before adding anything new.

## How To Use

Open a project folder and read its README first. Most projects include:

- a sanitized PowerShell script
- fake input data
- generated sample output
- a demo check under `tests/`
- notes explaining what was sanitized

## License

MIT. See [LICENSE](LICENSE).
