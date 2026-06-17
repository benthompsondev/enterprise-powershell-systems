# Sanitization Notes

## Project Name

`password-remediation-workflow-demo`

## What I Kept From The Original Idea

The private source scripts had the shape of a larger weak-password remediation system: CSV conversion, one-active-file intake, directory lookups, JSON run state, scheduled multi-pass processing, staged notifications, exclusions, final reset planning, audit logs, snapshots, and archived evidence. This demo keeps that shape without exposing any real systems.

This public version was packaged so it could be shared safely on GitHub. The goal was not to flatten the work into a toy script. The goal was to remove private identifiers while keeping the operational shape of the original automation.

Preserved workflow ideas:

- convert a raw security export into the automation format
- enforce one active CSV in the input folder
- import a password review export
- validate required columns before planning action
- hash the CSV to identify the active cycle
- create and update a local cycle state file
- lock a compliance cutoff at the start of the cycle
- resolve users against directory-style data
- classify standard, disabled, service/special, exempt, and missing users
- re-check mock directory data on every pass
- stop processing users who become compliant after the cutoff
- separate Reminder1, FinalReminder, ForceReset, Compliant, and Skip paths
- block state advancement if required action would fail
- create notification drafts
- create audit, summary, and snapshot reports
- archive CSV/state at the final simulated pass
- simulate account action instead of touching real accounts

## What Was Removed Or Replaced

- [x] employer or organization names
- [x] real domains, OUs, hostnames, and server paths
- [x] real users, emails, employee IDs, departments, and managers
- [x] real SMTP, Exchange, AD, and file share integrations
- [x] real credentials, tokens, secrets, and certificate material
- [x] production logs, exports, screenshots, and private run state

## Public Replacements

- `example.local`
- fake users
- fake departments
- fake manager emails
- fake raw security export
- fake converted password review export
- mock directory CSV
- local output folder
- local state folder
- local archive folder
- simulation logs

## Why It Is Safe

The scripts do not call Active Directory, Exchange, SMTP, Entra ID, Microsoft 365, ticketing tools, scheduled tasks, credential stores, or file shares. They read local fake CSV files, build a stateful plan, write local reports, simulate what would happen, and archive fake evidence locally.

## How To Check It

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1
```
