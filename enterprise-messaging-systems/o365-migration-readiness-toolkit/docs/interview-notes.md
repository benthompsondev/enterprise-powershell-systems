# Interview Notes

## Short Version

I built scripts like this during a staged move from on-prem Exchange to O365. The main problem was that users, shared mailboxes, licensing, and public folders did not all move at the same time.

The automation helped check what was ready, what was blocked, and what needed cleanup before the next migration batch.

## What I Would Talk Through

- Shared mailboxes could not always move just because the mailbox existed. I had to check whether every user with access had already moved to O365.
- Licensing was tied to directory groups, so the scripts checked whether users had the right group and whether any accounts had duplicate license paths.
- Public folders needed cleanup because the target cloud setup did not support them the same way. Some were archived, some were reviewed, and some were converted to shared mailboxes.
- Soft-deleted mailbox issues came up during migration, so I built repeatable checks and repair planning instead of handling every case manually.
- The useful part was the reporting. The scripts gave the team a clear list of ready items, blocked items, and cleanup work.

## What This Shows

- I can turn a messy migration process into repeatable checks.
- I understand why staged migrations need guardrails.
- I can write PowerShell that produces reviewable output before touching live systems.
- I care about logs, reports, and making work easier for the next admin.
