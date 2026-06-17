# Script Index

This page is the quick map for the whole repo.

The scripts are sanitized demos. They use fake CSVs, local output folders, and simulated actions so the workflow can be shared publicly. The useful part is the pattern: input, validation, planning, output, logging, and a check that proves the demo still runs.

For the bigger GitHub map, including Ledger and the rest of my public portfolio, start with the [Full Portfolio Map](https://github.com/benthompsondev/benthompsondev/blob/main/docs/portfolio-map.md).

## Account, Access, And Security

| Folder | Script | What it does |
| --- | --- | --- |
| [learner-onboarding-automation](../enterprise-healthcare-systems/learner-onboarding-automation/) | [Invoke-AccountOnboardingDemo.ps1](../enterprise-healthcare-systems/learner-onboarding-automation/scripts/Invoke-AccountOnboardingDemo.ps1) | Runs the full onboarding flow: intake validation, account action planning, group/access planning, mailbox planning, handoff files, notifications, logs, and sample outputs |
| [password-remediation-workflow](../enterprise-healthcare-systems/password-remediation-workflow/) | [Convert-WeakPasswordExportDemo.ps1](../enterprise-healthcare-systems/password-remediation-workflow/scripts/Convert-WeakPasswordExportDemo.ps1) | Converts a messy security export into the normalized CSV shape the remediation workflow expects |
| [password-remediation-workflow](../enterprise-healthcare-systems/password-remediation-workflow/) | [Invoke-PasswordRemediationDemo.ps1](../enterprise-healthcare-systems/password-remediation-workflow/scripts/Invoke-PasswordRemediationDemo.ps1) | Runs a staged weak-password remediation cycle with mock directory checks, state tracking, reminder planning, final action planning, archive output, and audit logs |

## Identity And Workforce Migration

| Folder | Script | What it does |
| --- | --- | --- |
| [workforce-platform-identity-migration](../enterprise-identity-systems/workforce-platform-identity-migration/) | [Test-WorkforceSourceDataDemo.ps1](../enterprise-identity-systems/workforce-platform-identity-migration/scripts/Test-WorkforceSourceDataDemo.ps1) | Checks messy workforce source data for missing fields, duplicate identifiers, unclear status, and rows that need review |
| [workforce-platform-identity-migration](../enterprise-identity-systems/workforce-platform-identity-migration/) | [New-WorkforceAccountActionPlanDemo.ps1](../enterprise-identity-systems/workforce-platform-identity-migration/scripts/New-WorkforceAccountActionPlanDemo.ps1) | Plans account creation, re-enable, update, and project OU movement using fake directory data |
| [workforce-platform-identity-migration](../enterprise-identity-systems/workforce-platform-identity-migration/) | [Export-ProjectOuReviewDemo.ps1](../enterprise-identity-systems/workforce-platform-identity-migration/scripts/Export-ProjectOuReviewDemo.ps1) | Exports a current-state project OU report so a project team can track which accounts are ready or blocked |
| [workforce-platform-identity-migration](../enterprise-identity-systems/workforce-platform-identity-migration/) | [New-MailboxLicenseActionPlanDemo.ps1](../enterprise-identity-systems/workforce-platform-identity-migration/scripts/New-MailboxLicenseActionPlanDemo.ps1) | Plans mailbox and license actions for users who need messaging access during the project |

## Endpoint Migration

| Folder | Script | What it does |
| --- | --- | --- |
| [browser-bookmark-migration](../enterprise-endpoint-systems/browser-bookmark-migration/) | [Invoke-BrowserBookmarkMigrationDemo.ps1](../enterprise-endpoint-systems/browser-bookmark-migration/scripts/Invoke-BrowserBookmarkMigrationDemo.ps1) | Backs up Chrome bookmarks, merges them into Edge favorites, keeps a manual recovery path, and writes a run report |
| [workstation-migration-state-toolkit](../enterprise-endpoint-systems/workstation-migration-state-toolkit/) | [Export-OldDeviceStateDemo.ps1](../enterprise-endpoint-systems/workstation-migration-state-toolkit/scripts/Export-OldDeviceStateDemo.ps1) | Captures old-device state into per-device evidence folders with app, printer, and local group inventory |
| [workstation-migration-state-toolkit](../enterprise-endpoint-systems/workstation-migration-state-toolkit/) | [Restore-NewDeviceStateDemo.ps1](../enterprise-endpoint-systems/workstation-migration-state-toolkit/scripts/Restore-NewDeviceStateDemo.ps1) | Reads captured state and plans what should be restored on the new device |
| [workstation-migration-state-toolkit](../enterprise-endpoint-systems/workstation-migration-state-toolkit/) | [Invoke-DirectoryComputerMigrationDemo.ps1](../enterprise-endpoint-systems/workstation-migration-state-toolkit/scripts/Invoke-DirectoryComputerMigrationDemo.ps1) | Simulates the IT-side directory prep: group membership, OU movement, and tracking output |

## Microsoft 365 / Messaging Migration

| Folder | Script | What it does |
| --- | --- | --- |
| [o365-migration-readiness-toolkit](../enterprise-messaging-systems/o365-migration-readiness-toolkit/) | [Invoke-O365MigrationSuiteDemo.ps1](../enterprise-messaging-systems/o365-migration-readiness-toolkit/scripts/Invoke-O365MigrationSuiteDemo.ps1) | Runs the full messaging migration demo and writes the combined summary |
| [o365-migration-readiness-toolkit](../enterprise-messaging-systems/o365-migration-readiness-toolkit/) | [Invoke-O365MigrationReadinessDemo.ps1](../enterprise-messaging-systems/o365-migration-readiness-toolkit/scripts/Invoke-O365MigrationReadinessDemo.ps1) | Runs the main readiness checks for a staged on-prem to O365 migration |
| [o365-migration-readiness-toolkit](../enterprise-messaging-systems/o365-migration-readiness-toolkit/) | [Export-UserMigrationWavePlanDemo.ps1](../enterprise-messaging-systems/o365-migration-readiness-toolkit/scripts/Export-UserMigrationWavePlanDemo.ps1) | Plans user migration waves and flags missing or blocked data |
| [o365-migration-readiness-toolkit](../enterprise-messaging-systems/o365-migration-readiness-toolkit/) | [New-O365LicenseGroupPlanDemo.ps1](../enterprise-messaging-systems/o365-migration-readiness-toolkit/scripts/New-O365LicenseGroupPlanDemo.ps1) | Checks license group readiness and duplicate license paths |
| [o365-migration-readiness-toolkit](../enterprise-messaging-systems/o365-migration-readiness-toolkit/) | [Test-SharedMailboxMigrationReadinessDemo.ps1](../enterprise-messaging-systems/o365-migration-readiness-toolkit/scripts/Test-SharedMailboxMigrationReadinessDemo.ps1) | Checks shared mailbox permissions and blocks unsafe shared mailbox moves until delegates are ready |
| [o365-migration-readiness-toolkit](../enterprise-messaging-systems/o365-migration-readiness-toolkit/) | [New-PublicFolderRetirementPlanDemo.ps1](../enterprise-messaging-systems/o365-migration-readiness-toolkit/scripts/New-PublicFolderRetirementPlanDemo.ps1) | Plans public folder archive, review, or conversion work before migration |
| [o365-migration-readiness-toolkit](../enterprise-messaging-systems/o365-migration-readiness-toolkit/) | [New-MailboxIssueRepairPlanDemo.ps1](../enterprise-messaging-systems/o365-migration-readiness-toolkit/scripts/New-MailboxIssueRepairPlanDemo.ps1) | Plans soft-deleted mailbox and mailbox-state repair work |
| [o365-migration-readiness-toolkit](../enterprise-messaging-systems/o365-migration-readiness-toolkit/) | [O365MigrationDemo.Shared.ps1](../enterprise-messaging-systems/o365-migration-readiness-toolkit/scripts/O365MigrationDemo.Shared.ps1) | Shared helper functions used by the messaging migration scripts |

## Support And Code Review

| Folder | Script | What it does |
| --- | --- | --- |
| [enterprise-support-and-code-review-utilities](../enterprise-support-systems/enterprise-support-and-code-review-utilities/) | [Invoke-SupportUtilitySuiteDemo.ps1](../enterprise-support-systems/enterprise-support-and-code-review-utilities/scripts/Invoke-SupportUtilitySuiteDemo.ps1) | Runs the support utility suite and writes a combined summary |
| [enterprise-support-and-code-review-utilities](../enterprise-support-systems/enterprise-support-and-code-review-utilities/) | [New-DhcpReservationReviewDemo.ps1](../enterprise-support-systems/enterprise-support-and-code-review-utilities/scripts/New-DhcpReservationReviewDemo.ps1) | Reviews fake DHCP reservation requests for invalid MACs, duplicate IPs, and out-of-scope requests |
| [enterprise-support-and-code-review-utilities](../enterprise-support-systems/enterprise-support-and-code-review-utilities/) | [Get-WindowsUpdateRemediationTargetsDemo.ps1](../enterprise-support-systems/enterprise-support-and-code-review-utilities/scripts/Get-WindowsUpdateRemediationTargetsDemo.ps1) | Builds a device remediation report for Windows update troubleshooting |
| [enterprise-support-and-code-review-utilities](../enterprise-support-systems/enterprise-support-and-code-review-utilities/) | [Get-EndpointProfileCleanupTargetsDemo.ps1](../enterprise-support-systems/enterprise-support-and-code-review-utilities/scripts/Get-EndpointProfileCleanupTargetsDemo.ps1) | Finds endpoints with many real user profiles while excluding system and support accounts |
| [enterprise-support-and-code-review-utilities](../enterprise-support-systems/enterprise-support-and-code-review-utilities/) | [Export-SecurityGroupAuditDemo.ps1](../enterprise-support-systems/enterprise-support-and-code-review-utilities/scripts/Export-SecurityGroupAuditDemo.ps1) | Produces a manager-friendly security group access review export |

## How To Verify A Script

Each project folder has a `tests/Run-DemoCheck.ps1` file. That is the fastest way to prove the demo still runs.

From the repo root, the full set is listed in the main `README.md`. GitHub Actions runs the same kind of checks automatically.
