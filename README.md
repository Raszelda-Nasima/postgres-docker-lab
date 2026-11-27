# PostgreSQL & Docker Lab

A local, containerized PostgreSQL environment for practicing Docker, Linux systems administration, database operations, backups, and monitoring. Docker Compose runs PostgreSQL 16 alongside PgAdmin 4.

## Requirements

- Docker Engine or Docker Desktop
- Docker Compose
- GNU Make (optional)

## Start locally

```bash
cp .env.example .env
# Edit .env and set a secure DB_PASSWORD
docker-compose up -d
docker-compose ps
```

- PostgreSQL: `localhost:5433` (container port 5432)
- PgAdmin: `http://localhost:5050`

Connect to PostgreSQL:

```bash
docker-compose exec postgres psql -U postgres -d myapp_db
```

## Features

- PostgreSQL 16 and PgAdmin 4 orchestrated with Docker Compose
- Persistent database volume and isolated bridge network
- PostgreSQL health check and service startup dependency
- Environment-based configuration and SQL initialization scripts
- Make shortcuts for local lifecycle, logs, database access, backups, and health checks
- Compressed backup/restore scripts, monitoring, and optional SQL auditing
- Local setup, operations, and architecture guides

## Useful commands

```bash
make help
make up
make status
make logs
make test
make health-check
make backup
make down
```

`docker-compose down` stops the services but retains database data. `docker-compose down -v` also removes the data volume.

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md), [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), and [OPS_QUICKSTART.md](OPS_QUICKSTART.md).
