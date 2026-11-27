# Architecture Overview

The lab runs PostgreSQL 16 and PgAdmin 4 as containers on the `postgres_network` Docker bridge.

- **PostgreSQL:** image `postgres:16-alpine`; Compose service `postgres`; explicit container name `postgres_db`.
- **PgAdmin:** image `dpage/pgadmin4:latest`; container name `pgadmin`; published on host port 5050 with `SCRIPT_NAME=/pgadmin`.
- **Persistence:** `postgres_data` stores the PostgreSQL data directory across container restarts and recreation.
- **Networking:** services can resolve each other by Compose service name. PostgreSQL host port 5433 maps to container port 5432.
- **Health:** PostgreSQL uses `pg_isready`; PgAdmin depends on PostgreSQL reaching the healthy state.
- **Initialization:** `init-scripts/` is mounted read-only into PostgreSQL's initialization directory. `01_schema.sql` runs only when the database data directory is first initialized and defines `users`, `products`, and `orders` without inserting sample rows.
- **Operations:** SQL role/audit/performance utilities are in `security/` and `monitoring/`; backup and restore scripts are in `backup-scripts/`.

## Startup and data flow

1. Compose creates `postgres_network` and `postgres_data`, then starts the PostgreSQL service.
2. On first initialization of an empty data directory, the PostgreSQL image creates the configured database and runs mounted initialization SQL files.
3. The health check waits for PostgreSQL readiness. PgAdmin starts after the database service becomes healthy.
4. PgAdmin can reach PostgreSQL over the Compose network using service name `postgres`; host clients use `localhost:5433`.
5. PgAdmin is published at `localhost:5050` and configured with the `/pgadmin` script path.
6. Database files remain in `postgres_data` when containers are stopped or recreated. Removing the volume deletes the stored data.

## Configuration and operational caveat

Compose reads `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `PGADMIN_DEFAULT_EMAIL`, and `PGADMIN_DEFAULT_PASSWORD` from the environment, with defaults for `DB_USER` and `DB_NAME` only. Backup, restore, and health-check scripts currently target a container named `postgres`, not the configured container name `postgres_db`; they need adjustment to work with this Compose file.
