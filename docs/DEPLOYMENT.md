# Local Deployment Guide

This guide covers running the PostgreSQL and PgAdmin services on a local machine with Docker Compose. No cloud infrastructure is provisioned by this repository.

## Prerequisites

- Docker Engine or Docker Desktop with Docker Compose
- GNU Make (optional)
- Host ports 5433 and 5050 available

## Configure and start

```bash
cp .env.example .env
# Set unique values for DB_PASSWORD and PGADMIN_DEFAULT_PASSWORD in .env
docker-compose up -d
docker-compose ps
docker-compose logs -f postgres
```

Compose requires `DB_PASSWORD`, `PGADMIN_DEFAULT_EMAIL`, and `PGADMIN_DEFAULT_PASSWORD`. `DB_USER` defaults to `postgres`, and `DB_NAME` defaults to `myapp_db`.

- PostgreSQL is published at `localhost:5433` (container port 5432).
- PgAdmin is published at port 5050; because `SCRIPT_NAME=/pgadmin` is configured, use `http://localhost:5050/pgadmin`.

## Connect and verify

```bash
docker-compose exec postgres psql -U postgres -d myapp_db
docker-compose exec postgres pg_isready -U postgres -d myapp_db
docker-compose exec postgres psql -U postgres -d myapp_db -c "SELECT version();"
docker-compose exec postgres psql -U postgres -d myapp_db -c "\\dt public.*"
```

A host PostgreSQL client can connect with:

```bash
psql -h localhost -p 5433 -U postgres -d myapp_db
```

Substitute values from `.env` if you changed the default database user or name. The initialization script creates the schema on first initialization of an empty data volume; it is not rerun simply by restarting the services.

## Available Make targets

```bash
make security-roles
make audit-enable
make performance
```

These are the only targets in the current Makefile. For normal lifecycle operations, use `docker-compose up -d`, `docker-compose ps`, `docker-compose logs`, and `docker-compose down` directly.

## Backup and health utilities

Scripts are in `backup-scripts/` and `monitoring/check_database_health.sh`. They currently hard-code `CONTAINER_NAME="postgres"`, while Compose sets `container_name: postgres_db`; update the scripts or container name before running them. Do not rely on these commands until that mismatch is resolved. The restore script drops and recreates its target database, so verify the backup and target and confirm deliberately.

## Stop services and preserve data

```bash
docker-compose down
```

This removes containers but retains the `postgres_data` named volume. `docker-compose down -v` also removes that volume and permanently deletes its database contents. Do not use volume removal as a schema migration strategy.
