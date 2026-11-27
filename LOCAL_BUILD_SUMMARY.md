# PostgreSQL Docker Lab — Local Build Summary

This project provides a local PostgreSQL environment using Docker Compose, with PgAdmin for browser-based administration.

## Architecture

- PostgreSQL 16 runs in a container and stores database files in the `postgres_data` named volume.
- PgAdmin runs in a separate container on the `postgres_network` bridge.
- PostgreSQL is available on host port 5433; PgAdmin is available at `http://localhost:5050`.
- SQL initialization scripts create the sample schema when the database volume is first initialized.

## Capabilities

- Persistent data across container restarts
- Environment-variable configuration via `.env`
- Database initialization scripts and sample data
- PostgreSQL health checks and service startup dependency
- CLI and PgAdmin access
- Database backup and restore scripts
- Monitoring and auditing utilities

## Common commands

```bash
cp .env.example .env
docker-compose up -d
docker-compose ps
docker-compose exec postgres psql -U postgres -d myapp_db
make health-check
make backup
docker-compose down
```

To remove the database data as well as containers, run `docker-compose down -v`.
