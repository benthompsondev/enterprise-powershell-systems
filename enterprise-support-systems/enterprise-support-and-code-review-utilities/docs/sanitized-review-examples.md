# Sanitized Code Review Examples

These examples are based on the kind of review work behind this folder, but they are rewritten with fake details and generic systems.

They are not copied from private emails or internal documents.

## Example 1: DHCP Reservation Script Review

### Request

A networking team has a PowerShell script that adds DHCP reservations from a CSV.

### What I Looked For

- Does the script validate the DHCP server target?
- Does it confirm the requested scope before adding reservations?
- Does it catch IPs outside the expected range?
- Does it catch malformed MAC addresses?
- Does it flag duplicate requested IPs?
- Does it write a review file or log after the run?
- Can the team test it before running against live infrastructure?

### Main Review Notes

| Area | Finding | Safer change |
| --- | --- | --- |
| Target safety | Server and scope values can be typed incorrectly | Put target values near the top and validate them before action |
| CSV quality | Bad MAC/IP values could go straight into the action step | Validate MAC format and expected IP range before changes |
| Duplicate requests | Two rows could request the same IP | Group by requested IP and flag duplicates first |
| Evidence | Console-only output is hard to review later | Write a CSV review file with status and notes |
| Operator clarity | The next person may not know what the script expects | Add a short comment block with purpose, input, output, and owner |

### Plain-English Response Back To The Team

I reviewed the script and the basic idea makes sense. The main risk is not the PowerShell syntax itself, it is accidentally adding a reservation to the wrong target or using bad CSV data.

Before using it broadly, I would add validation around the DHCP target, scope, MAC address, and requested IP. I would also write a review CSV so the team has a record of what was accepted, rejected, or skipped.

## Example 2: Web Traffic Simulation Script Review

### Request

A security team has a script that makes repeated web requests so their monitoring tools can detect and review generated traffic.

### What I Looked For

- Does it change the local system, or does it only create outbound test traffic?
- Does it explain the purpose and how to stop it?
- Does it handle unreachable sites or failed requests?
- Does it use delays so the output is not unrealistic or too noisy?
- Does the console output help the operator know what happened?
- Would the script be safe to run in a test context?

### Main Review Notes

| Area | Finding | Safer change |
| --- | --- | --- |
| Stop behavior | Long-running loop may be unclear to stop | Document keyboard stop behavior and handle interruption cleanly |
| Request failures | Failed requests can make the output confusing | Add timeout and warning handling |
| Run clarity | Operator may not know what the script is doing | Print clear startup notes and timestamped request output |
| Test realism | Fixed timing is less useful for monitoring tests | Add randomized wait time between requests |
| Risk level | Script does not change local settings | Mark as lower risk, while still documenting network traffic behavior |

### Plain-English Response Back To The Team

I reviewed the traffic generation script and it looks lower risk because it is not changing accounts, devices, registry values, or files. The main improvements are around clarity and failure handling.

I would make the run instructions obvious, add timeout handling for failed requests, and make the output show which request ran and whether it succeeded. That gives the security team better test data and makes the script easier to stop if needed.

## Example 3: Browser Update Scheduled Task Review

### Request

An endpoint team has a helper script that checks for a browser update and creates a scheduled task to run it daily.

### What I Looked For

- Does it log where the update check ran?
- Does it record the version before and after?
- Does it explain where the scheduled task is created?
- Does it make the process-close behavior clear?
- Does it use `try` / `catch` around task creation and update calls?
- Can another admin troubleshoot it later?

### Main Review Notes

| Area | Finding | Safer change |
| --- | --- | --- |
| Scheduled execution | Hidden scheduled tasks can confuse support later | Document task name, trigger, and script path clearly |
| Logging | Without logs, support cannot prove what happened | Write a timestamped local log |
| User impact | Closing browser processes can surprise users | Make the behavior clear and only do it when needed |
| Version proof | No before/after evidence | Log browser version before and after the update check |
| Error handling | Task registration or update can fail | Wrap risky commands in `try` / `catch` and log failures |

### Plain-English Response Back To The Team

I reviewed the update helper and the useful part is the scheduled check plus logging. The part I would make clearer is user impact and troubleshooting.

If the script may close a browser after an update, that should be obvious in the notes. I would also log the version before and after, the scheduled task name, and any failure so support has something to check later.

## What These Reviews Have In Common

The same pattern keeps showing up:

1. Understand what the script is supposed to accomplish.
2. Identify what it touches.
3. Decide what could go wrong.
4. Add validation before action.
5. Add output or logging someone can review.
6. Explain the feedback in normal language.

That is the code review story this folder is meant to show.
