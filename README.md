# Enterprise PowerShell Systems

[![PowerShell demo checks](https://github.com/benthompsondev/enterprise-powershell-systems/actions/workflows/powershell-demo-check.yml/badge.svg)](https://github.com/benthompsondev/enterprise-powershell-systems/actions/workflows/powershell-demo-check.yml)

This is my main PowerShell portfolio repo. It contains sanitized systems, scripts, fixes, and automations inspired by real enterprise healthcare IT workflow problems I have worked on.

The focus is practical systems work: messy CSV inputs, account and access planning, Microsoft 365 / Exchange-style handoffs, endpoint support, reporting, validation, logs, handoff files, and output another admin can review.

These are public-safe demos. Private organizational details are removed and replaced with fake data, safe examples, and clear run steps.

## Start Here

If you are reviewing this quickly, open these in order:

1. [Learner Onboarding Automation](enterprise-healthcare-systems/learner-onboarding-automation/) - the larger account/access planning workflow.
2. [Password Remediation Workflow](enterprise-healthcare-systems/password-remediation-workflow/) - the stateful security follow-up workflow.
3. [Browser Bookmark Migration Utility](enterprise-endpoint-systems/browser-bookmark-migration/) - the endpoint migration workflow.
4. [Workstation Migration State Toolkit](enterprise-endpoint-systems/workstation-migration-state-toolkit/) - the device replacement workflow.
5. `.github/workflows/powershell-demo-check.yml` - the GitHub Actions check that runs the demos.

The fastest proof that the repo works is the green GitHub Actions badge above. The fastest local check is:

```powershell
powershell -ExecutionPolicy Bypass -File .\enterprise-healthcare-systems\learner-onboarding-automation\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-healthcare-systems\password-remediation-workflow\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-endpoint-systems\browser-bookmark-migration\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-endpoint-systems\workstation-migration-state-toolkit\tests\Run-DemoCheck.ps1
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

## Current Systems

| Status | Project | What It Shows |
| --- | --- | --- |
| Flagship | [Learner Onboarding Automation](enterprise-healthcare-systems/learner-onboarding-automation/) | Scheduled CSV ingest, source backup, account lifecycle planning, AD-style matching, Exchange/mailbox planning, group membership, upstream response exports, ServiceNow-style handoff, notification drafts, reports, and validation |
| Flagship | [Password Remediation Workflow](enterprise-healthcare-systems/password-remediation-workflow/) | Security export conversion, stateful remediation cycles, mock directory checks, staged notifications, duplicate-run protection, audit output, and safe final reset planning |
| Endpoint automation | [Browser Bookmark Migration Utility](enterprise-endpoint-systems/browser-bookmark-migration/) | Chrome-to-Edge bookmark migration, multi-user profile discovery, HTML backups, recursive bookmark handling, Edge merge without overwriting existing favorites, reporting, and a manual recovery path |
| Endpoint automation | [Workstation Migration State Toolkit](enterprise-endpoint-systems/workstation-migration-state-toolkit/) | Old-device capture, new-device restore planning, printer/app/local group inventory, master tracking CSV, per-device evidence folders, and directory group/OU migration planning |

## What This Shows

These projects are meant to show how I think through operations automation:

- take a messy input file seriously
- validate before planning
- separate planning from action
- write output another admin can review
- keep logs and sample reports
- use fake data so the workflow can be shared safely
- add demo checks so the repo is not just a folder of scripts

## Quick Verification

Run the demo checks from the repo root:

```powershell
Set-Location .\enterprise-healthcare-systems\learner-onboarding-automation
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1

Set-Location ..\password-remediation-workflow
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1

Set-Location ..\..\enterprise-endpoint-systems\browser-bookmark-migration
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1

Set-Location ..\workstation-migration-state-toolkit
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

## How To Use

Open a project folder and read its README first. Most projects include:

- a sanitized PowerShell script
- fake input data
- generated sample output
- a demo check under `tests/`
- notes explaining what was sanitized
