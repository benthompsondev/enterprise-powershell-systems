# Reviewer Notes

## Short Version

I built scripts like this during a staged move from on-prem Exchange to O365. It was a long project with thousands of users, hundreds of shared mailboxes, public folders, licensing cleanup, workstation/phone support, and a lot of follow-up issues.

The useful part was that the scripts were not all trying to do the same thing. Each script solved a different migration problem and turned manual checking into repeatable reports or action plans.

## What I Would Point Out

- User migration was its own problem. I needed scripts to show who had already moved, who still needed to move, who was missing data, and who needed licensing first.
- Shared mailboxes were separate. A mailbox could only move once every delegated user was already migrated and licensed, so the scripts checked permissions and blocked unsafe moves.
- Licensing was tied to AD groups, so the scripts checked whether users had the right license group and whether any accounts had duplicate license paths.
- Public folders needed cleanup because the target cloud setup did not support them the same way. Some were archived, some were reviewed, and some were converted to shared mailboxes.
- Soft-deleted mailbox issues came up during migration, so I built repeatable checks and repair plans instead of treating every one like a one-off emergency.
- The value was the reporting and the guardrails. The scripts gave the team a clear list of ready items, blocked items, cleanup work, and data gaps.

## What This Shows

- I can turn a messy multi-year migration process into smaller repeatable tools.
- I understand why staged cloud migrations need guardrails and reporting.
- I can write PowerShell that produces reviewable output before touching live mailboxes, groups, or permissions.
- I care about logs, reports, and making work easier for the next admin.
