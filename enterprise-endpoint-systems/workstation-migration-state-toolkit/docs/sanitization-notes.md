# Sanitization Notes

This project is a sanitized version of a work-inspired workstation replacement toolkit.

## What Was Preserved

- three-script workflow: old device capture, new device restore planning, IT directory prep
- contractor-friendly run pattern
- per-device evidence folders
- master tracking CSV
- installed program inventory
- printer inventory and restore planning
- local group membership inventory
- computer baseline capture
- managed application restore planning
- directory OU and computer group migration planning
- logs, manifests, CSV output, JSON output, and simulated apply logs

## What Was Removed Or Replaced

- employer names
- real computer names
- real user or technician names
- internal domains and OU paths
- production group names
- real printer names and ports
- internal file shares
- real migration logs
- direct Active Directory writes
- direct computer rename/restart actions in the public demo

## Public-Safe Replacements

- fake computer names such as `OLD-WIN10-042` and `NEW-WIN11-042`
- fake `example.local` directory values
- local output paths
- mock directory CSV
- simulated apply logs
- demo-only tracking rows

## Safety Notes

Do not commit real device captures, printer exports, local group exports, directory exports, migration tracking files, screenshots, hostnames, domains, or support call notes.
