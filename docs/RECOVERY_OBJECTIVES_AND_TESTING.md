# Recovery objectives and restore testing

This document defines how to set and validate recovery objectives for the local Docker Compose PostgreSQL lab. It is a test plan, not evidence that a restore has already succeeded. Record measured results before making recovery-time or recovery-point claims.

## Scope and limitations

The current backup design uses a host scheduler and local backup files. It does not provide off-host protection, point-in-time recovery, replication, or a tested recovery guarantee. A host or disk loss can destroy both the database and its local backups. Perform restore tests on a disposable, isolated host or Docker environment—not on the working database.

## Define recovery objectives

Agree and record objectives before a test:

- **Target RPO:** maximum acceptable data loss, measured as the time between the last recoverable committed change and the simulated incident. Daily backups alone can imply close to a day's potential data loss; a successful schedule does not guarantee every backup ran or is usable.
- **Target RTO:** maximum acceptable elapsed time from declaring the incident to verifying that the restored database is available and correct.
- **Backup cadence and retention:** record the installed schedule and how many local restore points are retained.

The repository does not prescribe numeric RPO or RTO targets. Leave targets as `TBD` until the project owner chooses them. A measured test result is evidence for one test scenario, not a guarantee of future recovery time.

## Restore-test procedure

Run this test monthly as a suggested lab practice, and after changes to backup, restore, database, or infrastructure configuration. Record the date and actual test cadence. Use a disposable machine or isolated Docker host with Docker Compose and GNU Make installed.

1. **Prepare isolation.** Confirm the test environment cannot reach or target the working database. Do not run restore tests against the normal local Compose project. Use a separate host/VM if possible; keep the test backup and its copy clearly identified.
2. **Select a backup.** Choose a completed `full_backup_*.sql.gz` from the host backup directory. Record its filename, size, file timestamp, and checksum (`sha256sum <file>`). Copy it to the isolated test host using a secure method. Never treat a second directory on the same host as off-host protection.
3. **Record the recovery point.** For a meaningful RPO test, create a known test marker in the disposable source database before taking a test backup, and record its commit time and identifier. After the backup, make another disposable marker and record it too. Do not add test data to a real application database. The restored database should contain the pre-backup marker and not the post-backup marker.
4. **Start an isolated database.** Check out the project on the test host, create a test-only `.env` with unique credentials, and start Compose there:

   ```bash
   cp .env.example .env
   # Set unique test-only DB_PASSWORD and PGADMIN_DEFAULT_PASSWORD values.
   docker compose up -d postgres
   docker compose ps
   ```

   Use a separate Docker host/VM so the Compose container names and published ports cannot conflict with the working lab. Never copy production credentials into a disposable test environment.
5. **Start the RTO timer** when the simulated recovery is declared (or at the explicitly documented start point), then restore the selected backup:

   ```bash
   make restore BACKUP=/absolute/path/to/full_backup_YYYYMMDD_HHMMSS.sql.gz
   ```

   Confirm the database name shown by the script is the test database, then type `yes` only in this isolated environment. The restore drops and recreates the configured database.
6. **Verify recovery.** Require the restore command to exit successfully. Verify the three table counts it prints, check the expected pre-backup marker and absence of the post-backup marker, inspect required schema/indexes, and run a representative application query or health check. Save command output and logs.
7. **Stop the RTO timer** only after all verification checks pass and record the elapsed time. If restore or verification fails, record a failed test and investigate; do not report the run as successful.
8. **Clean up safely.** Keep the test record and evidence according to project policy. Remove only the isolated test Compose project and its test volume after confirming the environment and project name. Do not use `docker compose down -v` in the working project.

### Measuring RPO

For the marker-based exercise, record the timestamp/identifier of the newest committed marker present in the restored copy and the simulated incident time. The observed recovery-point gap is the elapsed time between those points. Also record whether the expected post-backup marker was absent. For a real incident, RPO is the amount of committed data since the latest usable recovery point that could not be recovered; the backup schedule alone is not proof of that value.

### Measuring RTO

Use one consistent start and end definition for every test:

- **Start:** incident/recovery declaration or the start of the documented restore operation. Pick one and use it consistently.
- **End:** restored service is available and all verification checks pass.

Record elapsed wall-clock time, including troubleshooting and failed attempts if the objective is end-to-end recovery. Do not exclude time simply to make the result fit a target.

## Test record template

Copy this section for each exercise:

| Field | Result |
|---|---|
| Test date and operator | TBD |
| Environment isolated from working database? | TBD |
| Backup filename / checksum | TBD |
| Backup created at / size | TBD |
| Backup gzip integrity check | Pass / Fail |
| Target RPO / target RTO | TBD / TBD |
| Incident or test start time | TBD |
| Restore completed time | TBD |
| Verification completed time | TBD |
| Measured RTO | TBD |
| Newest recoverable marker / timestamp | TBD |
| Simulated incident time | TBD |
| Measured RPO | TBD |
| Schema, indexes, counts, and application query verified | Pass / Fail; evidence: TBD |
| Result and issues found | Pass / Fail; details: TBD |
| Follow-up actions and owner | TBD |

## Reporting

Until an isolated restore test has passed, describe the repository as having backup and restore scripts with a documented test plan—not as having tested disaster recovery. After testing, report the actual date, scenario, measured RPO/RTO, and limitations. Local-only backups remain vulnerable to host loss; address off-host copies separately before claiming host-disaster recovery.
