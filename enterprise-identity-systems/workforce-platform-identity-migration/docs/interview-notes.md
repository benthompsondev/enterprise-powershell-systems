# Interview Notes

## Short Version

I built scripts to help with the identity side of a workforce/payroll platform migration. The project data was messy, so the scripts validated the source rows, checked whether users already existed, planned new accounts or re-enabled accounts, moved accounts into a project OU, filled in important attributes, and later helped plan mailbox/licensing and termination cleanup.

The key point is that the scripts did not just blindly create accounts. They produced reports and review buckets so questionable rows could be checked before action.

## Good Talking Points

- Source data was not clean enough to process blindly.
- Matching used stable identifiers first, then fell back to username/display name.
- Disabled accounts were flagged because automation cannot always know whether a disabled account should really be re-enabled.
- Account creation and re-enable paths were separated.
- Follow-up reports helped the project team see what was completed and what still needed review.
- Later scripts handled mailbox/license planning and termination cleanup.
- The workflow produced logs and CSVs so the project team could track progress.

## What This Says About My Work

This is the kind of automation I like building: practical scripts around messy real data, with enough guardrails that the output can be reviewed.

The important lesson was that automation is not just speed. For identity work, it also needs checks, review points, and honest limits about what the script can and cannot know.
