# Security Policy

This repo is public and open source, but it is built from sanitized demo workflows.

Please do not open issues, pull requests, screenshots, logs, or examples that contain:

- real employer names
- internal domains, hostnames, IPs, tenant IDs, client IDs, or ticket numbers
- usernames, real email addresses, phone numbers, or personal data
- production exports, logs, reports, screenshots, or raw script output
- secrets, passwords, tokens, certificates, keys, connection strings, or `.env` values

## Reporting A Problem

If you spot something that looks sensitive, do not paste it into a public issue.

Open a short issue that says a privacy/security review is needed and only describe the category, not the value. Example:

```text
Possible internal hostname in sample output.
```

That gives me enough to investigate without spreading the value further.

## Demo Safety

The scripts in this repo use fake data, local files, and simulated outputs. They are meant to be useful skeletons for people building similar automation in their own environment, but they should be reviewed and adapted before real use.

Before using anything against live systems:

- replace demo data with your own safe test data first
- read the script comments and README for that folder
- test with non-production targets
- confirm logging and output paths
- review any action section before enabling real changes
- follow your own organization's change, security, and privacy rules

The public repo should stay safe to clone, run, and review without exposing private workplace data.
