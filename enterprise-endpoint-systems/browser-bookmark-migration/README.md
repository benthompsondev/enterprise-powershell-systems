# Browser Bookmark Migration Utility

This is a sanitized PowerShell utility for a Chrome-to-Edge bookmark migration workflow on Windows endpoints.

The real problem was simple but easy to mishandle: standardize users on Microsoft Edge without making people feel like their Chrome bookmarks disappeared. The script backs up Chrome bookmarks first, then merges them into existing Edge favorites instead of replacing what is already there.

This is the kind of endpoint automation I like because it is small, practical, and built around avoiding user pain.

## What It Does

- discovers local Windows user profiles
- skips system-style profiles by default
- finds each user's Chrome bookmark JSON
- creates a timestamped HTML backup before changing Edge data
- keeps the backup in a format Edge can manually import
- reads existing Microsoft Edge favorites
- merges Chrome bookmark folders into Edge without wiping existing favorites
- keeps nested bookmark folders instead of flattening everything
- writes a CSV migration report and run log
- makes browser closing and Edge restart optional instead of forcing it every time

## The Problem This Solves

In an enterprise migration, browser standardization is not just a technical setting. Users care about their saved links, and losing bookmarks creates avoidable tickets and complaints.

This script was built around that reality:

- back up first
- preserve existing Edge favorites
- migrate per Windows user profile
- keep folder structure
- leave a manual recovery path if the automated merge does not work
- write output support staff can review

## How It Works

The basic flow is:

```text
profile discovery -> Chrome bookmark read -> HTML backup -> Edge bookmark read -> merge -> report/log
```

The script reads Chrome and Edge bookmark files as JSON. For each user profile with Chrome bookmarks, it creates an HTML backup named like:

```text
ChromeBookmarks-demo.alex-20260616-143000.html
```

Then it creates a folder under Edge's Other favorites area:

```text
Chrome bookmarks from demo.alex
```

Existing Edge favorites are left in place.

## Manual Recovery Path

The HTML backup is not just for storage. It can be manually imported into Edge if the automated merge does not work or if a user later says something is missing.

In Edge:

1. Open Favorites.
2. Choose Import favorites.
3. Select `Favorites or bookmarks HTML file`.
4. Pick the generated HTML backup file.

Imported bookmarks appear under:

```text
Other Favorites > Backup Chrome Bookmarks
```

That recovery path was an important part of the design. It gives support staff a simple fallback instead of relying only on the automated merge.

## Run The Demo

From this folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1
```

Expected result:

```text
Demo check passed.
```

The test creates fake user profiles under `output-test`, runs the migration, checks that the HTML backup was created, verifies that existing Edge favorites were preserved, and confirms that nested Chrome bookmarks were copied into Edge.

## Example Usage

Run against fake or test profiles:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Invoke-BrowserBookmarkMigrationDemo.ps1 `
    -ProfileRootPath .\examples\mock-profiles `
    -BackupRootPath .\output\backups `
    -OutputDirectory .\output
```

Run against normal Windows profiles with a local backup path:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Invoke-BrowserBookmarkMigrationDemo.ps1 `
    -ProfileRootPath C:\Users `
    -BackupRootPath C:\Temp\ChromeBookmarkBackups `
    -OutputDirectory C:\Temp\ChromeBookmarkMigration
```

Browser handling is explicit because force-closing browsers can be disruptive:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Invoke-BrowserBookmarkMigrationDemo.ps1 `
    -CloseBrowsers `
    -RestartEdge
```

## What This Shows

- PowerShell automation for endpoint migration work
- Windows user profile discovery
- Chrome and Edge bookmark file handling
- JSON parsing and writing
- recursive bookmark/folder traversal
- backup-before-change design
- preserving existing user data during migration
- support-friendly fallback steps
- CSV reporting and plain run logs
- safe defaults for disruptive actions

## What This Says About My Work

This one is smaller than the migration toolkits, but it shows an important habit: I try to build automation around the user impact, not only the technical setting.

The technical goal was browser standardization. The practical problem was avoiding lost bookmarks, avoidable tickets, and support frustration. That is why the script backs up first, preserves folder structure, merges instead of replacing, writes logs, and leaves a manual recovery path.

## What Was Changed For The Demo

This is not a raw workplace script.

The public version removes or generalizes:

- employer names
- internal share paths
- real usernames
- internal migration notes
- private comments
- organization-specific settings

The useful architecture is still here: multi-profile processing, HTML backup, recursive bookmark handling, Edge merge behavior, missing-file handling, and reviewable output.

## Privacy And Safety

Do not commit real bookmark exports, real usernames, internal URLs, private domains, hostnames, ticket numbers, screenshots, or production logs.

The included demo check uses fake profiles and fake `example.local` URLs only.
