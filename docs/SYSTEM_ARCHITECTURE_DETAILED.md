# Detailed Local System Architecture

This document describes the local Docker Compose setup. It does not describe a cloud deployment; Terraform files in this repository declare no infrastructure resources.

## Services and networking

| Component | Configuration |
|---|---|
| PostgreSQL | `postgres:16-alpine`; Compose service `postgres`; container `postgres_db`; container port 5432, published as host port 5433 |
| PgAdmin | `dpage/pgadmin4:latest`; container `pgadmin`; container port 80, published as host port 5050; `SCRIPT_NAME=/pgadmin` |
| Network | User-defined bridge network `postgres_network` |
| Storage | Named volume `postgres_data`, mounted at `/var/lib/postgresql/data` |

PostgreSQL's health check runs `pg_isready` using the configured database user and database name. PgAdmin waits for that health check before starting. Services communicate over the Compose network using the service name `postgres`.

## Configuration

The Compose file takes these settings from environment variables, usually loaded from `.env`:

- `DB_USER` (default `postgres`)
- `DB_PASSWORD` (required; no default)
- `DB_NAME` (default `myapp_db`)
- `PGADMIN_DEFAULT_EMAIL` (required)
- `PGADMIN_DEFAULT_PASSWORD` (required)

The example template is `.env.example`. Replace example credentials and keep `.env` untracked.

## Initialization and runtime flow

1. Compose creates the bridge network and persistent volume and starts PostgreSQL.
2. When the data directory is empty, the PostgreSQL image initializes the configured database and runs files mounted from `init-scripts/`.
3. `init-scripts/01_schema.sql` creates the `users`, `products`, and `orders` tables, constraints, and order lookup indexes. It inserts no example rows and does not rerun on an already initialized volume.
4. PostgreSQL becomes healthy; PgAdmin starts and can reach it over the internal network.
5. Host clients connect through `localhost:5433`; PgAdmin is published at `localhost:5050/pgadmin`.
6. Stopping or recreating containers retains database files in `postgres_data`. Removing the volume deletes those files.

## Operations and boundaries

- The Makefile defines `security-roles`, `audit-enable`, and `performance` targets.
- Security scripts optionally create non-login roles and row-change auditing for the three business tables.
- The performance SQL runs read-only statistics queries; no monitoring service or extension is enabled by the Compose file.
- Shell scripts provide backup, restore, and health-check functionality, but currently assume the container is named `postgres`; the Compose file names it `postgres_db`.
- There is no TLS setup in the Compose configuration. The database port is published on the host; restrict host/network access as appropriate for the local environment.
