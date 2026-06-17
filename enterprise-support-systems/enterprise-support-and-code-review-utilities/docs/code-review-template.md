# Code Review Packet Template

This is the kind of template I would use for an internal script review after stripping out private details.

The goal is simple: make the script safer, clearer, and easier for the owning team to run without turning the review into a giant formal process.

## Request Summary

**Requesting team:** `<team name>`

**Script name:** `<script name>`

**Purpose:** `<what the script is meant to do>`

**Systems touched:** `<DHCP, endpoint, browser, file share, security tooling, directory data, etc.>`

**Expected operator:** `<who will run it>`

**Expected frequency:** `<one-time, daily, weekly, as needed>`

## Initial Risk Read

**Risk level:** Low / Medium / High

**Why:** `<plain-English reason>`

Examples:

- Low: reads data or writes a local report only
- Medium: changes a system setting, creates a task, or writes to a shared location
- High: changes identity, access, networking, production devices, or large batches of systems

## What I Checked

- What does the script change?
- Does it validate input before doing anything important?
- Are server names, paths, scopes, URLs, or targets hard-coded?
- Does it explain how to run and stop it?
- Does it log success and failure clearly?
- Does it fail safely if a value is missing or invalid?
- Can another admin understand the output?
- Is there a dry-run or report-first option?
- Is there anything that should be approved by the owning team before running?

## Findings

| Area | Finding | Risk | Suggested change |
| --- | --- | --- | --- |
| Input validation | `<what is missing or unclear>` | Low / Medium / High | `<recommended fix>` |
| Error handling | `<what happens on failure>` | Low / Medium / High | `<recommended fix>` |
| Logging/output | `<what is hard to review later>` | Low / Medium / High | `<recommended fix>` |
| Operator safety | `<what someone could misunderstand>` | Low / Medium / High | `<recommended fix>` |

## Suggested Code Changes

- Add a comment block explaining purpose, input, output, and owner.
- Move hard-coded values into parameters near the top.
- Validate important values before making changes.
- Add `try` / `catch` around commands that can fail.
- Write a log or CSV output that can be reviewed after the run.
- Make the success and failure messages obvious.
- Add a dry-run or report mode when the script could change production systems.

## Testing Notes

What I tested:

- `<manual run with fake input>`
- `<invalid input test>`
- `<expected output check>`
- `<failure path checked>`

What I did not test:

- `<production execution>`
- `<permission behavior>`
- `<external system response>`

## Suggested Response Back To The Team

Hi `<team>`,

I reviewed the script and the overall idea makes sense. The main thing I would tighten before running it is `<main risk>`.

I added notes around `<validation/logging/error handling/usage instructions>` so it is easier to run safely and easier to troubleshoot if something does not work as expected.

Before using it broadly, I would test it with fake or limited input, confirm the output, and have the owning team approve the final targets.

Thanks,
`<reviewer>`
