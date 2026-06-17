# Code Review Workflow Notes

This page is a sanitized summary of the code review side of this folder.

The real review context is private, so this page does not include raw emails, internal names, domains, tickets, paths, server names, private URLs, private IPs, or exact copied script text.

## The Role I Was Filling

I was helping with internal script/code review work for other technical teams.

That meant I was not only writing my own PowerShell. I was also reviewing scripts another team wanted to run, checking whether the logic was safe enough, improving parts of the code when needed, and writing feedback the team could actually use.

The useful part was the combination:

- read the request and understand the real operational goal
- review the script for risk, clarity, and failure points
- improve comments, validation, logging, and run instructions
- explain what changed and why in plain English
- help the owning team learn from the review instead of just handing back edits

## What I Was Usually Checking

When another team brought a script forward, I looked for practical things:

- does the script clearly say what it does
- does it validate input before doing anything important
- are risky values hard-coded when they should be parameters
- could it affect the wrong device, scope, group, URL, or path
- does it write output another person can review later
- does it explain what changed and what did not change
- does it fail clearly when source data is wrong
- does it have logging or at least useful console output
- can the owning team understand the script after the review
- is the risk level clear before it is used

The goal was not to make every script fancy. The goal was to make it safer to run and easier for the owning team to understand.

## What I Usually Changed

The changes were usually practical:

- added a summary comment block at the top
- added usage notes so the next person knew how to run it
- moved risky values into variables or parameters
- added `try` / `catch` around commands likely to fail
- added validation for input files, IP addresses, MAC addresses, paths, or URLs
- added logging or CSV output so results were not only on screen
- made error messages clearer
- added a safer test path before anything production-like happened

## Sanitized Case Study: DHCP Reservation Review

One review involved a DHCP reservation script.

The script's job was to add reservations, but the review focus was really about safety:

- what if the DHCP server target was wrong
- what if the scope was wrong
- what if the requested IP was outside the expected scope
- what if the MAC address was malformed
- what if two rows requested the same IP
- what proof would exist after the run

The public demo keeps that review idea by reading fake DHCP reservation requests and writing a review CSV before anything would be changed.

## Sanitized Case Study: Web Traffic Simulation Review

Another review involved a script meant to create web traffic for security testing and threat hunting.

That kind of script is lower risk than a script that changes accounts or devices, but it still needs review:

- does it explain what traffic it creates
- does it handle failed requests without crashing
- can the operator stop it cleanly
- does it randomize timing enough for the test goal
- does it avoid changing the local system
- are the instructions clear enough for someone else to run it

The main review value was making the script easier to run, easier to stop, and easier to understand from the output.

## Sanitized Case Study: Browser Update Scheduled Task Review

Another review area involved a browser update helper that created a scheduled task and wrote logs.

This type of script needs more caution because it can create scheduled execution and interact with running browser processes.

The review questions were:

- where does the script write logs
- what account context does the scheduled task run under
- what happens if the browser is open
- does it check the installed version before and after
- does it fail cleanly
- would another admin know where the task and log live

The useful part of that review was adding clearer logging, task setup notes, and operator expectations.

## Sanitized Feedback Examples

These are representative examples, rewritten with fake details:

| Area | Review point |
| --- | --- |
| DHCP reservation work | Validate MAC address format, confirm the requested IP belongs to the selected scope, and flag duplicate IP requests before implementation |
| Web traffic simulation | Add timeout/error handling, explain how to stop the loop, and make the console output show what happened |
| Browser update scheduled task | Log the installed version before and after, document the task path, and make the browser-close behavior clear |
| Windows update troubleshooting | Separate devices that are already patched from devices that need reboot, disk cleanup, inventory refresh, or remediation |
| Endpoint profile cleanup | Exclude system, service, and support profiles so cleanup reports do not accidentally target accounts that should stay |
| Security group audits | Export a manager-readable report and flag disabled accounts, stale access, nested groups, and service accounts for review |

## What This Shows

This project is partly about PowerShell, but it is also about review judgment.

Good internal automation needs more than a script that runs once. It needs clear input, clear output, enough validation to catch bad rows, and comments that help another technical person understand why the script is doing something.

It also shows something I think matters in real IT work: being able to review someone else's script respectfully, explain the risk, make it better, and leave the team with something they can run more safely next time.
