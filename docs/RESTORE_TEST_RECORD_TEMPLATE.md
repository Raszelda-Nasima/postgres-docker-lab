# Restore-test evidence record

Copy this file to a dated filename for each test, for example `docs/restore-tests/2026-11-27.md`. Commit only non-sensitive results. Do not commit credentials, customer data, or raw database dumps.

## Objectives

- Target RPO: TBD (owner-approved target)
- Target RTO: TBD (owner-approved target)
- Backup cadence / retention: TBD
- Test cadence: Monthly suggested; actual cadence: TBD

## Test details

- Date and operator: TBD
- Isolated disposable host/VM and project identifier: TBD
- Verified no connection to working database: TBD
- Backup filename: TBD
- Backup SHA-256: TBD
- Backup creation timestamp and size: TBD
- Backup gzip integrity: Pass / Fail

## Measurements

- Recovery start definition used: Incident declared / Restore command started (choose one)
- Recovery start timestamp: TBD
- Restore completion timestamp: TBD
- Verification completion timestamp: TBD
- Measured RTO: TBD
- Simulated incident timestamp: TBD
- Newest recovered committed marker and timestamp: TBD
- Post-backup marker correctly absent: Pass / Fail
- Measured RPO: TBD

## Verification

- Restore command exited successfully: Pass / Fail
- Expected schema and indexes present: Pass / Fail
- `users` row count: TBD
- `products` row count: TBD
- `orders` row count: TBD
- Representative application query / health check: Pass / Fail (details: TBD)
- Logs/evidence location (no secrets or data): TBD

## Outcome and actions

- Overall result: Pass / Fail
- Issues or deviations: TBD
- Follow-up action, owner, due date: TBD
- Cleanup of isolated environment confirmed: Yes / No
