# Portfolio Setup Guide

## Project overview

This repository is a local PostgreSQL 16 and PgAdmin lab managed with Docker Compose. It demonstrates container orchestration, persistent volumes, initialization SQL, database roles, row-change auditing, PostgreSQL statistics, and shell-based operational tooling. The Terraform directory currently contains placeholders and does not provision infrastructure.

## Run the project

Prerequisites: Docker Engine or Docker Desktop with Docker Compose. GNU Make is optional.

```bash
cp .env.example .env
# Set unique DB_PASSWORD and PGADMIN_DEFAULT_PASSWORD values in .env
docker-compose up -d
docker-compose ps
docker-compose exec postgres psql -U postgres -d myapp_db
```

PostgreSQL is available on host port 5433 and PgAdmin is published on port 5050 with `SCRIPT_NAME=/pgadmin` (use `http://localhost:5050/pgadmin`). The database volume persists when containers stop.

## Demonstrated components

- `docker-compose.yml`: PostgreSQL 16 and PgAdmin services, health check, named volume, and bridge network
- `init-scripts/01_schema.sql`: `users`, `products`, and `orders` schema with constraints and indexes; no seed data
- `security/`: optional least-privilege group roles and INSERT/UPDATE/DELETE audit triggers
- `monitoring/performance.sql`: read-only database and table statistics
- `backup-scripts/`: compressed `pg_dump` backup and restore utilities
- `Makefile`: `security-roles`, `audit-enable`, and `performance` targets only

The backup, restore, and health-check scripts currently expect a container named `postgres`, whereas the Compose configuration sets `container_name: postgres_db`. This discrepancy should be fixed before demonstrating those scripts.

## Portfolio description

> A local PostgreSQL operations lab using Docker Compose, PostgreSQL 16, and PgAdmin. Includes persistent storage, schema initialization, optional role-based access grants, row-change auditing, database performance snapshots, and shell-based backup/restore utilities.

Before publishing screenshots or configuration, ensure `.env` and all real credentials remain private. See [the security guide](docs/SECURITY_AND_PERFORMANCE.md).
