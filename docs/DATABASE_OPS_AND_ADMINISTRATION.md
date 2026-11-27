# PostgreSQL Database Operations

This guide documents the local Docker Compose lab. Database security and performance features are PostgreSQL-based; there is no cloud deployment configuration.

## Database schema

`init-scripts/01_schema.sql` defines three tables in the `public` schema:

- `users`: unique username and email, identity primary key, and creation timestamp.
- `products`: name, optional description, positive price, non-negative stock, and creation timestamp.
- `orders`: foreign keys to users and products, positive quantity, non-negative total price, and order timestamp.

The script adds indexes for order user, product, order date, and user/date lookup. It creates schema objects only; it inserts no sample records. Docker runs initialization scripts only when it initializes an empty data volume.

## Optional security setup

Apply role grants and row-change auditing after the schema is available:

```bash
make security-roles
make audit-enable
```

`security/setup_roles.sql` creates `lab_readonly` and `lab_app` as `NOLOGIN` roles and grants permissions. It does not create login users or passwords.

`security/enable_auditing.sql` creates `audit.table_log` and triggers on `users`, `products`, and `orders`. It records INSERT, UPDATE, and DELETE operations, including row images and session user.

Inspect recent audit entries with:

```bash
docker compose exec postgres psql -U postgres -d myapp_db -c \
  "SELECT table_name, operation, session_user_name, occurred_at FROM audit.table_log ORDER BY occurred_at DESC LIMIT 20;"
```

## Performance checks

```bash
make performance
```

This runs the read-only queries in `monitoring/performance.sql`: database size, estimated live/dead table rows, cache hit statistics, and index usage.

## Backups and recovery

Create a compressed backup manually:

```bash
make backup
```

Backups are stored under `backups/` by default. Each completed dump is gzip-tested before being atomically moved into place. The default retention policy keeps the seven newest timestamped backup files; older files are removed only after a new backup succeeds.

Override the directory and retention count for a manual run:

```bash
BACKUP_DIR=/secure/path/pg-backups RETENTION_COUNT=14 make backup
```

### Schedule daily backups with host cron

The sample crontab runs a backup every day at 02:00 host local time. It assumes Linux, Docker Compose, `flock`, and a host user whose account can access Docker and the project checkout.

1. Replace `/absolute/path/to/postgres-docker-lab` in `backup-scripts/postgres-backup.cron.example` with the absolute checkout path.
2. Install the entry for the Docker-owning user:

   ```bash
   crontab -e
   ```

3. Paste the uncommented schedule line from the example. Do not install it as root unless root owns the intended Docker context and backup files.
4. Check `logs/backup-cron.log` after the scheduled time. The wrapper serializes scheduled executions with `flock`; if one is already running, the next run is logged and skipped.

The schedule and policy can be adjusted in the crontab. For example, to run at 02:00 daily while keeping 14 local copies:

```cron
0 2 * * * RETENTION_COUNT=14 /absolute/path/to/postgres-docker-lab/backup-scripts/scheduled_backup.sh
```

The wrapper logs stdout and errors to `logs/backup-cron.log`; `logs/` and `backups/` are git-ignored. Rotate or cap this log on long-running hosts. Backups and logs remain on the host by default, so this schedule alone does not protect against host or disk loss. Off-host copies are a separate recovery control.

Restore a backup manually (destructive; requires typing `yes`):

```bash
make restore BACKUP=./backups/full_backup_YYYYMMDD_HHMMSS.sql.gz
```

The restore command validates gzip integrity, drops and recreates the configured database, applies the dump, and reports row counts for the three business tables. Use only when recovery is intended or in an isolated test environment. Stop application writes and confirm the backup and database target before proceeding.

## Encryption and local secrets

Use a private `.env` based on `.env.example`, replace both example passwords, and keep it out of version control. The local Docker volume is not encrypted by PostgreSQL; protect the host disk and any copied backups according to the environment's security requirements.
