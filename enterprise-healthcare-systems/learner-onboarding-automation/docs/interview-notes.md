# Interview Notes

## Short Version

I built a PowerShell automation workflow that replaced a manual student / learner onboarding process in a hospital environment. It took CSV exports from a source system and turned them into account, access, mailbox, group membership, ServiceNow-style task, notification, and reporting work.

The original ran live, was tested and tuned over months, and supported high-volume onboarding periods with hundreds of learner records in a day and thousands across a month.

## What Made It Hard

- The CSV export could contain repeated rows for the same learner.
- Different access types had to turn into different account, group, mailbox, and application actions.
- Some users already existed, some were disabled, and some needed new accounts.
- Dates, flags, and identifiers had to be checked before any action was safe.
- Multiple teams needed different outputs from the same source data.
- The script needed enough logging and exports that a run could be reviewed later.

## Systems The Original Workflow Coordinated

- Active Directory style account lookup, creation, re-enable, and update logic
- Exchange / mailbox planning
- group membership and application access planning
- ServiceNow-style task handoff
- notification email preparation
- CSV import/export
- logging and review files

This public repo does not connect to those systems. It uses fake CSV data, fake directory data, local reports, and simulation logs to show the workflow safely.

## How To Explain The DevOps Value

This project is a good DevOps story because it shows practical automation habits:

- turn a manual process into a repeatable workflow
- validate input before acting
- separate planning from execution
- make output reviewable
- handle edge cases instead of assuming perfect data
- coordinate multiple systems from one source of truth
- produce logs and reports for traceability

## Good Interview Soundbite

I had a manual onboarding process that was eating a lot of application-team time. I built a PowerShell workflow that took the source CSV, validated the rows, merged duplicate learner records, checked whether accounts already existed, planned group and mailbox work, prepared ServiceNow-style handoffs and email notifications, and produced reviewable reports. The production version ran live and helped automate high-volume learner onboarding instead of having the team do the same account and access steps by hand.
