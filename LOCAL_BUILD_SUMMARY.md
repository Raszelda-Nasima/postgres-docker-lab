# PostgreSQL Docker Lab — Local Build Summary

This project runs PostgreSQL 16 and PgAdmin locally with Docker Compose. It is an operations practice environment, not a cloud deployment: the Terraform directory contains placeholder files with no declared resources.

## Architecture

- PostgreSQL uses image `postgres:16-alpine`, Compose service name `postgres`, and container name `postgres_db`.
- PgAdmin uses `dpage/pgadmin4:latest`, container name `pgadmin`, and `SCRIPT_NAME=/pgadmin`.
- Services share the `postgres_network` bridge network.
- PostgreSQL data is stored in the `postgres_data` named volume.
- PostgreSQL host port 5433 maps to container port 5432; PgAdmin host port 5050 maps to container port 80.
- PgAdmin starts after PostgreSQL passes its health check.
- `init-scripts/01_schema.sql` initializes `users`, `products`, and `orders` only when the data volume is initialized for the first time. It creates no sample rows.

## Capabilities in the code

- Environment configuration via `.env` / `.env.example`
- Optional SQL role grants, audit triggers, and performance snapshots
- Bash backup/restore and database health-check utilities
- Make targets for role grants, auditing, and performance queries

The Makefile does not define lifecycle, test, backup, restore, or health-check targets. Additionally, the operational shell scripts use container name `postgres`, which does not match Compose's `postgres_db`; they require correction before they work unchanged.

## Common commands

```bash
cp .env.example .env
# Edit .env and replace both example passwords
docker-compose up -d
docker-compose ps
docker-compose exec postgres psql -U postgres -d myapp_db
make security-roles
make audit-enable
make performance
docker-compose down
```

`docker-compose down -v` also removes the `postgres_data` volume and its contents.
