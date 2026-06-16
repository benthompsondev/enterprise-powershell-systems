# Sanitization Notes

This project is a sanitized version of a work-inspired browser migration utility.

## What Was Preserved

- multi-user Windows profile processing
- Chrome bookmark discovery per profile
- Edge bookmark discovery per profile
- backup-before-change behavior
- timestamped HTML bookmark backup
- browser-compatible manual import fallback
- recursive bookmark and folder handling
- merge behavior that preserves existing Edge favorites
- missing-file handling for profiles without Chrome bookmarks
- configurable browser close and Edge restart behavior
- CSV report and plain run log output

## What Was Removed Or Generalized

- employer names
- internal network shares
- internal server names
- real usernames
- department-specific comments
- organization-specific migration notes
- private paths
- production bookmark data

## Public-Safe Replacements

- backup paths are configurable and default to local demo-safe folders
- fake profile names are used in tests
- fake `example.local` URLs are used in generated fixtures
- disruptive browser behavior is opt-in through `-CloseBrowsers` and `-RestartEdge`

## Review Notes

This project should stay public-safe as long as nobody commits real browser bookmark files, screenshots, internal URLs, or production logs.
