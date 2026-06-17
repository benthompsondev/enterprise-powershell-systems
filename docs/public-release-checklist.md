# Public Release Checklist

Use this before adding another work-inspired PowerShell demo to the public repo.

The goal is simple: keep the real workflow shape, remove private data, and prove the demo runs.

## 1. Capture The Real Value

Before rewriting, note what makes the original useful:

- input files and messy-data problems
- systems touched
- validation checks
- planning vs action split
- logs, reports, summaries, and handoff files
- edge cases and failure paths
- what another admin or project team needed from the output

Do not publish the raw source, raw exports, screenshots, logs, or private notes.

## 2. Replace Private Details

Remove or rewrite:

- employer names and internal team names
- usernames, emails, phone numbers, employee IDs, and real user rows
- internal domains, hostnames, server names, IPs, tenant IDs, client IDs, and ticket numbers
- network paths, production logs, screenshots, and raw exports
- secrets, passwords, tokens, certificates, private keys, connection strings, and `.env` values

Use fake examples such as `example.local`, `user001`, `demo-ticket-1001`, local `examples/` files, and TEST-NET IP ranges.

## 3. Keep The Workflow Useful

Do not turn the script into a toy example just because it is public.

Try to keep:

- validation
- review buckets
- duplicate handling
- dry-run or simulation behavior
- CSV/JSON/log output
- comments explaining important choices
- test/demo checks
- sample output that shows the result without exposing private data

## 4. Add The Public Project Shape

Each public demo should include:

- `README.md`
- `scripts/`
- `examples/`
- `examples/sample-output/`
- `tests/Run-DemoCheck.ps1`
- `docs/sanitization-notes.md`
- `docs/reviewer-notes.md` when extra context helps

## 5. Run Checks Before Publishing

From the project folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-DemoCheck.ps1
```

From the repo root, run the workspace privacy scan when available:

```powershell
..\codex-home\scripts\Invoke-PrivacyScan.ps1 -Path .
```

Also search for obvious private or draft leftovers:

```powershell
rg -n "draft note|private note|TODO|password|secret|token|tenant|client id|hostname|internal"
```

Review findings manually. Fake demo values can be okay, but real private values are not.

## 6. Final Git Check

Before committing:

```powershell
git status --short
git diff --check
git diff --stat
```

Only public-safe files should be staged.

The commit message should sound normal and specific, for example:

```text
Add messaging migration readiness demo
Improve PowerShell repo release checklist
```
