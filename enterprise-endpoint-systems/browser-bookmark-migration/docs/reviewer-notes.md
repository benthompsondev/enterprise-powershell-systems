# Reviewer Notes

## Short Version

I built this kind of script to support a browser standardization effort where users needed to move from Chrome to Edge without losing their saved bookmarks.

The important part was not just copying a file. The script backs up Chrome bookmarks first, keeps the backup in a format Edge can manually import, then merges Chrome bookmarks into existing Edge favorites without wiping out what users already had.

## What I Would Point Out

- The script processes local Windows profiles instead of only the current user.
- It skips profiles cleanly when Chrome bookmarks do not exist.
- It creates a timestamped backup before changing Edge data.
- The HTML backup gives support staff a manual recovery path.
- It preserves nested bookmark folders.
- It merges into Edge instead of replacing the Edge bookmark file.
- Browser close/restart behavior is configurable because forcing it can disrupt users.
- It writes a CSV report and run log so the result is reviewable.

## What This Says About My Work

This is the kind of automation I like building: practical, careful around user data, and focused on reducing support problems.

The main design choice was safety. In a real endpoint migration, a script that technically works but wipes existing favorites would create more work. The better approach is backup first, merge carefully, report what happened, and leave a fallback path.
