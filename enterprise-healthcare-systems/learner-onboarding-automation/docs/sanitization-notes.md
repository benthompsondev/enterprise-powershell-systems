# Sanitization Notes

## Project Name

`account-onboarding-automation-demo`

## What I Kept From The Original Idea

The original script replaced a student / learner onboarding process and was tested and tuned as edge cases showed up. This sanitized version keeps the useful workflow shape while removing private details:

- import an external access CSV
- preserve scheduled-run context with a fake run profile
- make a local backup copy of the source export
- validate required fields before doing anything else
- merge multiple access rows for the same person
- look for an existing account using fake directory data
- decide whether to create, re-enable, or update an account
- create a unique username when one is missing
- handle display-name collisions
- normalize rotation and account dates
- catch CSV edge cases like shifted columns, unclear yes/no fields, bad statuses, and broken dates
- map access types to planned groups and actions
- split planned work into directory, Exchange/mailbox, and service desk handoff reports
- preserve the group membership, email notification, and ServiceNow-style task handoff pattern
- create CSV/JSON reports
- create a fake upstream response CSV with one row per access request
- create fake notification drafts
- create a run manifest and local log for review
- simulate the apply step without touching real systems

## What The Private Script Showed

Without exposing private details, the original showed a lot of real work:

- it had a long revision/comment history from testing and production tuning
- it handled directory account lookup and update paths
- it handled existing disabled accounts differently from new accounts
- it shaped source rows into custom user/access objects
- it generated passwords for planned new accounts
- it formatted output for downstream review
- it produced response rows for the upstream workflow
- it selected scheduled input runs and backed up files for audit/recovery
- it coordinated directory, mailbox, and service desk style work
- it planned group membership and application access from CSV flags
- it prepared notification details for other teams
- it produced exports and logs so runs could be checked

The public version keeps those ideas, but every system touch has been changed into fake data, local reports, or simulation output.

## What Was Removed Or Replaced

- [x] employer or organization names
- [x] real source system names
- [x] real OUs, domains, and tenant details
- [x] real users, emails, groups, and mailboxes
- [x] hostnames, IPs, network shares, and internal paths
- [x] credentials, tokens, secrets, and certificate material
- [x] real email recipients, SMTP settings, and ticket routing
- [x] logs, exports, screenshots, and production data

## Notes On The Rewrite

This is still a fresh public version, but it is intentionally closer to the original script's logic than the first pass.

The script does not call AD, Exchange, Microsoft 365, Entra ID, ticketing systems, SMTP, or file shares. Anywhere the real script would have touched one of those systems, this version creates a plan, report, draft, or simulation log instead.

The public placeholders are:

- `example.local`
- fake external person IDs
- fake users
- fake groups
- fake ticket IDs
- generic OUs
- local output folders

## Why It Is Worth Showing

This shows more than a small helper script. It represents an automation project that replaced a manual learner onboarding process and automated a lot of the repeated account/access work around it.

The public version keeps the workflow pattern in generic terms while removing the private organization name, real system names, real routing, and real data.

This was packaged as a public-safe demo with the goal of preserving the original workflow shape rather than flattening it into a toy example.

It shows that I worked through a real onboarding automation problem with moving parts:

- messy source data
- duplicate rows
- existing account matching
- account lifecycle decisions
- access planning
- group membership planning
- email and ticket handoff planning
- reporting
- review before action

That is the kind of PowerShell work that translates well into DevOps habits: validate input, make repeatable plans, log what happened, and keep the risky parts controlled.

## How To Check It

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1
```
