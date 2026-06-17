# Contributing

This is a personal portfolio repo, but the code is MIT licensed and meant to be reusable.

Issues, suggestions, and small pull requests are welcome if they make the demos clearer, safer, or easier to run.

## Before Opening A Pull Request

Please keep the same shape as the rest of the repo:

- use fake users, fake groups, fake domains, and local demo files
- do not add real workplace data or production exports
- keep scripts readable for another admin
- prefer reviewable output before simulated action
- add or update a demo check when behavior changes
- update the README if the run steps or output changes

## Local Checks

From the repo root, run the demo checks that match the folder you changed.

For the full repo:

```powershell
powershell -ExecutionPolicy Bypass -File .\enterprise-healthcare-systems\learner-onboarding-automation\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-healthcare-systems\password-remediation-workflow\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-identity-systems\workforce-platform-identity-migration\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-endpoint-systems\browser-bookmark-migration\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-endpoint-systems\workstation-migration-state-toolkit\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-messaging-systems\o365-migration-readiness-toolkit\tests\Run-DemoCheck.ps1
powershell -ExecutionPolicy Bypass -File .\enterprise-support-systems\enterprise-support-and-code-review-utilities\tests\Run-DemoCheck.ps1
```

## Privacy Rules

Do not submit:

- employer names or internal team names
- real usernames, emails, phone numbers, or user exports
- internal domains, hostnames, IPs, tenant IDs, client IDs, or ticket numbers
- production logs, screenshots, report exports, or raw script output
- passwords, API keys, tokens, certificates, private keys, or `.env` files

If you are using this repo as a starting point for your own organization, keep your local/private copy private until you have sanitized it.
