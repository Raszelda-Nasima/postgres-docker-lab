# PostgreSQL Database Operations

This guide documents the local Docker Compose lab. Database security and performance features are PostgreSQL-based; there is no cloud deployment configuration.

## Database schema

`init-scripts/01_schema.sql` defines three tables in the `public` schema:

- `users`: unique username and email, identity primary key, and creation timestamp.
- `products`: name, optional description, positive price, non-negative stock, and creation timestamp.
- `orders`: foreign keys to users and products, positive quantity, non-negative total price, and order timestamp.

The script adds indexes for order user, product, order date, and user/date lookup. Docker runs initialization scripts only when it initializes an empty data volume.

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

The repository provides `backup-scripts/full_backup.sh` and `backup-scripts/restore_backup.sh`. Both target the Compose service `postgres`, not an explicitly named container.

Create a backup:

```bash
make backup
```

Backups are gzip-compressed SQL dumps under `backups/`. A backup is moved into place only after `gzip -t` confirms that it is valid. The default retention policy keeps the newest seven backup files.

Override the backup location or retention with environment variables:

```bash
BACKUP_DIR=/secure/path/pg-backups RETENTION_COUNT=14 make backup
```

Restore a backup:

```bash
make restore BACKUP=./backups/full_backup_20231120_020000.sql.gz
```

The restore script validates the gzip file, requires typing `yes`, drops the configured database, recreates it, applies the dump, and prints row counts for the three business tables.

This is destructive and must not be run against a database unless an isolated test or explicit recovery is intended. Before recovery, stop application writes, confirm the dump target and database name, and copy the backup outside the host if the host itself may be affected.

## Encryption and local secrets

Use a private `.env` based on `.env.example`, replace both example passwords, and keep it out of version control. The local Docker volume is not encrypted by PostgreSQL; protect the host disk and any copied backups according to the environment's security requirements.
