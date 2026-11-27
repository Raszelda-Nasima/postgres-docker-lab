# Local PostgreSQL Operations Quick Start

This guide reflects the current Docker Compose services and scripts. The Compose service is named `postgres` and its container is explicitly named `postgres_db`.

## Start and connect

```bash
cp .env.example .env
# Set unique values for DB_PASSWORD and PGADMIN_DEFAULT_PASSWORD in .env
docker-compose up -d
docker-compose ps
docker-compose exec postgres psql -U postgres -d myapp_db
```

PgAdmin is configured with `SCRIPT_NAME=/pgadmin` and is published on port 5050; try `http://localhost:5050/pgadmin`. PostgreSQL is published on `localhost:5433`.

## Optional database features

The Makefile currently contains these database targets:

```bash
make security-roles
make audit-enable
make performance
```

`security-roles` creates `lab_readonly` and `lab_app` group roles and grants permissions. It does not create login users. `audit-enable` installs row-change triggers on `users`, `products`, and `orders`. Auditing records INSERT, UPDATE, and DELETE operations, not reads. `performance` runs read-only PostgreSQL statistics queries.

To inspect audit records after enabling auditing:

```bash
docker-compose exec postgres psql -U postgres -d myapp_db -c \
  "SELECT table_name, operation, session_user_name, occurred_at FROM audit.table_log ORDER BY occurred_at DESC LIMIT 20;"
```

## Health check and performance

```bash
docker-compose exec postgres pg_isready -U postgres -d myapp_db
make performance
```

`monitoring/check_database_health.sh` contains additional connection, database-size, table/index, and server-version queries. Note: this script currently assumes the container is named `postgres`, but `docker-compose.yml` sets `container_name: postgres_db`, so it will fail unless that name mismatch is corrected.

## Backups and recovery

The scripts are `backup-scripts/full_backup.sh` and `backup-scripts/restore_backup.sh`. They create/use compressed `.sql.gz` dumps under `backups/`; the restore script asks for confirmation and replaces the target database. Both scripts currently target a container named `postgres`, while the Compose container is named `postgres_db`. Resolve that mismatch before running them. Keep backups securely outside version control and verify a backup before relying on it.

## Maintenance

Run maintenance commands through the Compose service name:

```bash
docker-compose exec postgres psql -U postgres -d myapp_db -c "VACUUM ANALYZE;"
docker-compose exec postgres psql -U postgres -d myapp_db -c "REINDEX DATABASE myapp_db;"
```

## Guides

- [README.md](README.md) — project overview and start instructions
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) — local setup and verification
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Compose architecture
- [docs/DATABASE_OPS_AND_ADMINISTRATION.md](docs/DATABASE_OPS_AND_ADMINISTRATION.md) — schema and operations
- [docs/SECURITY_AND_PERFORMANCE.md](docs/SECURITY_AND_PERFORMANCE.md) — roles, auditing, and performance
