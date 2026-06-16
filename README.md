# Enterprise PowerShell Systems

This repo contains sanitized PowerShell examples based on real IT automation work.

The focus is practical systems work: messy CSV inputs, account and access planning, Microsoft 365 / Exchange-style handoffs, endpoint support, reporting, validation, and output another admin can review.

## What This Repo Is For

I work in healthcare IT and information systems. A lot of useful automation starts with a messy export, a manual checklist, and a process that needs to be safer and easier to repeat.

These are not raw workplace scripts. They are cleaned demo versions that keep the useful pattern while replacing private systems, paths, domains, users, tickets, and organization details with fake data.

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

## Quick Verification

Run the demo checks from the repo root:

```powershell
Set-Location .\enterprise-healthcare-systems\learner-onboarding-automation
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1

Set-Location ..\password-remediation-workflow
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
