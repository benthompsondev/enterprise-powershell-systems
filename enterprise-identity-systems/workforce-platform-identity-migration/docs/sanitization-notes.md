# Sanitization Notes

This project is a sanitized version of work-inspired identity automation for a Workday-style workforce platform migration.

## What Was Preserved

- multi-script workflow
- project CSV validation
- matching by employee ID, professional/license ID, username, and display name
- disabled-account detection
- duplicate and ambiguous match handling
- new account planning
- re-enable account planning
- project OU movement planning
- manager, title, department, employee ID, professional ID, and workforce ID planning
- project OU review reporting
- mailbox/license action planning
- termination review planning
- CSV, JSON, summary, and log output

## What Was Removed Or Replaced

- employer names
- real names and emails
- real domains
- real OU paths
- production group names
- mailbox routing domains
- tenant/license identifiers
- internal file shares
- temporary password records
- real reports and email content
- direct AD, Exchange, and licensing changes

## Public-Safe Replacements

- fake worker rows
- fake directory users
- fake project OU paths under `example.local`
- planned actions instead of direct system changes
- mock mailbox/license planning
- local output folders

## Safety Notes

Do not commit real workforce exports, HR data, account lists, disabled-user reports, license lists, temporary password files, emails, screenshots, tenant values, routing domains, or internal project notes.
