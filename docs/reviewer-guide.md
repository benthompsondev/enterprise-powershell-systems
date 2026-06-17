# Repo Reviewer Guide

This is a quick guide for someone looking through the repo for the first time.

The repo is organized by the kind of operational problem being solved. Each project uses fake data and simulated actions, but the workflow shape is based on real IT automation work.

## What To Look At First

1. Start with the root `README.md` to understand the overall story.
2. Open one project README and check the "What This Says About My Work" section.
3. Look at the matching `scripts\` folder to see the PowerShell flow.
4. Look at `examples\sample-output\` when available to see the kind of report or plan the script creates.
5. Check `tests\Run-DemoCheck.ps1` to see how the demo proves the workflow still runs.
6. Check the GitHub Actions badge to confirm the repo is validated automatically.

## What The Projects Are Meant To Prove

| Area | What to notice |
| --- | --- |
| Account and access onboarding | Messy CSV intake, duplicate handling, existing account matching, access planning, handoff files, and logs |
| Password remediation | Monthly state tracking, staged reminders, account re-checks, duplicate-run protection, audit output, and archive behavior |
| Workforce platform identity migration | 1000+ user source-data validation, create/re-enable planning, project OU reporting, mailbox/license planning, and review buckets |
| Workstation migration | Hundreds of device replacements, old-device capture, new-device restore planning, master tracking, per-device evidence folders, and IT directory prep |
| O365 migration support | Thousands of users, hundreds of shared mailboxes, license readiness, shared mailbox blockers, public folder cleanup, and mailbox repair planning |
| Browser bookmark migration | User-impact-focused endpoint automation with backups, merge behavior, logs, and manual recovery |
| Support and code review | Smaller support utilities plus sanitized review packets showing how I helped other teams improve scripts and testing habits |

## The Pattern Across The Repo

The same pattern shows up in most of the projects:

- read messy input
- validate before action
- separate planning from execution
- write CSV/JSON/log output that another person can review
- keep fake data public-safe
- add a demo check so the project is not just static files

That is the point of this repo. It is meant to show practical PowerShell and operations automation work, not perfect toy examples.

## Privacy Note

These are sanitized demos. They do not contain raw workplace scripts, real users, internal system names, private paths, production exports, tickets, screenshots, or credentials.
