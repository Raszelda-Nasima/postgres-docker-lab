# PostgreSQL & Docker Lab

A local PostgreSQL 16 lab for practicing Docker Compose, Linux systems administration, database operations, backups, and monitoring. Compose runs PostgreSQL and PgAdmin on an isolated bridge network, with a named volume for database persistence.

## Requirements

- Docker Engine or Docker Desktop with Docker Compose
- GNU Make (optional; only the targets listed below are provided)

## Start locally

Create a private `.env` file and replace both example passwords before starting:

```bash
cp .env.example .env
# Edit DB_PASSWORD and PGADMIN_DEFAULT_PASSWORD in .env
docker-compose up -d
docker-compose ps
```

Compose requires `DB_PASSWORD`, `PGADMIN_DEFAULT_EMAIL`, and `PGADMIN_DEFAULT_PASSWORD`. `DB_USER` defaults to `postgres`; `DB_NAME` defaults to `myapp_db`.

- PostgreSQL: `localhost:5433` (container port 5432)
- PgAdmin: `http://localhost:5050/pgadmin` (the Compose service sets `SCRIPT_NAME=/pgadmin`)

Connect to PostgreSQL using the configured database credentials:

```bash
docker-compose exec postgres psql -U "$DB_USER" -d "$DB_NAME"
```

Or, with the defaults:

```bash
docker-compose exec postgres psql -U postgres -d myapp_db
```

## What the lab provides

- PostgreSQL 16 Alpine and PgAdmin containers
- `postgres_data` named volume and `postgres_network` bridge network
- PostgreSQL health check; PgAdmin waits for PostgreSQL to become healthy
- First-initialization schema setup from `init-scripts/01_schema.sql` (`users`, `products`, and `orders`; no sample rows are inserted)
- Optional role grants and row-change auditing in `security/`
- Read-only performance queries and a database health-check script in `monitoring/`
- Compressed backup and restore scripts in `backup-scripts/`

The `Makefile` currently defines `security-roles`, `audit-enable`, and `performance`; it does not define the lifecycle, backup, restore, test, or health-check shortcuts mentioned in some older guides. Also, the backup/restore and health-check scripts currently assume a container named `postgres`, while Compose names its container `postgres_db`; that mismatch must be resolved before those scripts will work unchanged.

## Useful commands

```bash
docker-compose up -d
docker-compose ps
docker-compose logs -f postgres
docker-compose exec postgres psql -U postgres -d myapp_db
make security-roles
make audit-enable
make performance
docker-compose down
```

`docker-compose down` stops and removes the containers but retains the database volume. `docker-compose down -v` also deletes the persisted database data.

## Documentation

- [Local deployment](docs/DEPLOYMENT.md)
- [Architecture overview](docs/ARCHITECTURE.md)
- [Detailed architecture](docs/SYSTEM_ARCHITECTURE_DETAILED.md)
- [Database operations](docs/DATABASE_OPS_AND_ADMINISTRATION.md)
- [Security and performance](docs/SECURITY_AND_PERFORMANCE.md)
- [Operations quick start](OPS_QUICKSTART.md)
- [Quick reference](QUICK_REFERENCE.md)
