# Sanitization Notes

This demo is based on several Exchange/O365 migration support scripts, but it is not a copy of the private workplace scripts.

## What Was Kept

- staged on-prem Exchange to O365 migration workflow
- separate scripts for separate migration problems
- user migration wave planning
- shared mailbox readiness checks
- delegated user migration blockers
- license-backed AD group readiness checks
- duplicate license path review
- public folder archive, conversion, and permission cleanup planning
- soft-deleted mailbox repair planning
- CSV intake and CSV reporting
- review-first output before any real change

## What Was Changed

- real users were replaced with fake `example.local` users
- real mailbox names were replaced with generic examples
- real groups were replaced with fake `LIC-*` and `APP-*` group names
- real domains, tenant details, hostnames, servers, and internal paths were removed
- real Exchange and Active Directory commands were replaced with local CSV simulation and action plans
- production exports were replaced with small fake examples

## Why This Is Safe To Share

The scripts do not connect to Exchange, Active Directory, Entra ID, or Microsoft 365.

They read local fake CSV files and write local output files. The value is in the migration logic, separate problem areas, and reporting shape, not in any private data.
