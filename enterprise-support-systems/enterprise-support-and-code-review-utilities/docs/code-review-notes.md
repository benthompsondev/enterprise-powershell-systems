# Code Review Notes

This page is a sanitized summary of the kind of code review and support work behind this demo.

The real review context is private, so this page does not include raw emails, internal names, domains, tickets, paths, server names, or exact copied script text.

## What I Was Usually Checking

When another team brought a script forward, I was usually looking for practical things:

- does it validate input before doing anything important
- are risky values hard-coded when they should be parameters
- does it write output another person can review
- does it explain what changed and what did not change
- does it fail clearly when the source data is wrong
- can the team understand the script after the review

The goal was not to make every script fancy. The goal was to make it safer to run and easier for the owning team to understand.

## Example Review Feedback, Sanitized

These are representative examples, rewritten with fake details:

| Area | Review point |
| --- | --- |
| DHCP reservation work | Validate MAC address format, make sure the requested IP belongs to the selected scope, and flag duplicate IP requests before implementation |
| Windows update troubleshooting | Separate devices that are already patched from devices that need reboot, disk cleanup, inventory refresh, or remediation |
| Endpoint profile cleanup | Exclude system, service, and support profiles so cleanup reports do not accidentally target accounts that should stay |
| Security group audits | Export a manager-readable report and flag disabled accounts, stale access, nested groups, and service accounts for review |

## What This Shows

This project is partly about PowerShell, but it is also about review habits.

Good internal automation needs more than a script that runs once. It needs clear input, clear output, enough validation to catch bad rows, and comments that help another technical person understand why the script is doing something.

That is the part I wanted this folder to show.
