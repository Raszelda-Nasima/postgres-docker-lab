# PostgreSQL Database Operations

This guide documents the local Docker Compose lab. Database security and performance features are PostgreSQL-based; there is no cloud deployment configuration.

## Database schema

`init-scripts/01_schema.sql` defines three tables in the `public` schema:

- `users`: unique username and email, identity primary key, and creation timestamp.
- `products`: name, optional description, positive price, non-negative stock, and creation timestamp.
- `orders`: foreign keys to users and products, positive quantity, non-negative total price, and order timestamp.

The script adds indexes for order user, product, order date, and user/date lookup. It creates schema objects only; it inserts no sample records. Docker runs initialization scripts only when it initializes an empty data directory. Existing named volumes are preserved and do not automatically receive later initialization changes.

## Optional security setup

Apply role grants and row-change auditing after the schema is available:

```bash
make security-roles
make audit-enable
```

`security/setup_roles.sql` creates `lab_readonly` and `lab_app` as `NOLOGIN` roles and grants permissions. It does not create login users or passwords. The role that executes the default-privilege statements determines which future objects those defaults apply to.

`security/enable_auditing.sql` creates `audit.table_log` and triggers on `users`, `products`, and `orders`. It records INSERT, UPDATE, and DELETE operations, including row images and session user; it does not record SELECT statements. Audit rows are part of the same transaction as the original change.

Inspect recent audit entries with:

```bash
docker-compose exec postgres psql -U postgres -d myapp_db -c \
  "SELECT table_name, operation, session_user_name, occurred_at FROM audit.table_log ORDER BY occurred_at DESC LIMIT 20;"
```

## Performance checks

```bash
make performance
```

This runs the read-only queries in `monitoring/performance.sql`: database size, estimated live/dead table rows, cache hit statistics, and index usage. These are PostgreSQL statistics, not a separate monitoring service, and their interpretation depends on workload and statistics collection. The script does not require an extension. Query plans can be inspected with `EXPLAIN (ANALYZE, BUFFERS)` on representative queries.

## Backups and recovery

The repository provides `backup-scripts/full_backup.sh` and `backup-scripts/restore_backup.sh`. The backup script uses `pg_dump`, gzip-compresses its output, writes files under `backups/`, and retains up to seven matching backups. The restore script requires a `.sql.gz` backup, prompts for confirmation, drops and recreates its hard-coded database, then restores and checks row counts.

**Important:** Both scripts currently set `CONTAINER_NAME="postgres"`, while the Compose configuration sets `container_name: postgres_db`. Correct this mismatch before running the scripts with the provided Compose setup. The scripts also hard-code the default database/user. Store verified backups securely outside the repository. Never use `docker-compose down -v` as a migration method; it deletes the database volume.

## Encryption and local secrets

Use a private `.env` based on `.env.example`, replace both example passwords, and keep it out of version control. The local Docker volume is not encrypted by PostgreSQL; protect the host disk and backup files with operating-system or storage encryption and appropriate access controls. The Compose configuration does not enable TLS. PostgreSQL is published on a host port, so restrict access to the machine/network as appropriate.
