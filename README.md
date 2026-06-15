# Enterprise PowerShell Systems

This repo contains sanitized, public-safe examples of enterprise PowerShell systems and automation workflows I built or adapted from real IT work.

The examples are framed around practical systems administration and DevOps-style automation: CSV-driven workflows, identity and access planning, Microsoft 365 / Exchange-style operations, endpoint support, reporting, validation, and handoff between teams.

## Why This Repo Exists

I work in healthcare IT and information systems, where a lot of useful automation starts with a messy CSV export, a manual checklist, and a process that needs to be safer and more repeatable.

The projects here are not raw workplace scripts. They are cleaned, sanitized versions that preserve the automation pattern while replacing private systems, paths, domains, users, tickets, and organization details with fake data.

The goal is to show how I think through real operational automation:

- validate input before planning changes
- separate planning from execution
- produce reviewable reports and handoff files
- handle duplicate rows, missing values, existing accounts, and unclear flags
- keep logs and demo checks so the workflow can be trusted

## Current Systems

| Status | Project | What It Shows |
| --- | --- | --- |
| Flagship | [Learner Onboarding Automation](enterprise-healthcare-systems/learner-onboarding-automation/) | CSV ingest, account lifecycle planning, AD-style matching, Exchange/mailbox planning, group membership, ServiceNow-style handoff, notification drafts, reports, and validation |

## Quick Verification

Run the flagship demo check from the repo root:

```powershell
Set-Location .\enterprise-healthcare-systems\learner-onboarding-automation
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1
```

Expected result:

```text
Demo check passed.
```

## Resume Alignment

These projects connect to my experience with:

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
- interview notes for discussing the project professionally
