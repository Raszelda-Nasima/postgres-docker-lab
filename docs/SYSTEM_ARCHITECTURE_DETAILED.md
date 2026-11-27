# Local-only system architecture

This document describes the local Docker Compose setup. PostgreSQL 16 and PgAdmin 4 run as separate containers connected by the `postgres_network` bridge.

## Services and persistence

- PostgreSQL uses `postgres:16-alpine`, reads its credentials from environment variables, and runs SQL initialization files from `init-scripts/` on first initialization.
- PostgreSQL data is stored in the `postgres_data` named volume and persists when containers are stopped or recreated.
- PgAdmin uses `dpage/pgadmin4:latest` and waits for PostgreSQL's health check before starting.
- PostgreSQL is exposed on host port 5433 (container port 5432); PgAdmin is exposed on host port 5050.

## Request and initialization flow

1. Compose creates the network and volume and starts PostgreSQL.
2. PostgreSQL initializes its data directory and executes mounted initialization scripts.
3. PgAdmin connects to PostgreSQL by service name over the Compose network.
4. Users connect with `psql` on `localhost:5433` or manage the database in the browser at `http://localhost:5050`.

Removing the named volume with `docker-compose down -v` permanently deletes the persisted database files.
