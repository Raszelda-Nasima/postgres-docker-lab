# Local Deployment Guide

This guide covers running PostgreSQL and PgAdmin on your machine with Docker Compose.

## Prerequisites

- Docker Desktop or Docker Engine
- Docker Compose
- 2 GB free disk space
- Host ports 5433 and 5050 available

## Start services

```bash
cp .env.example .env
# Edit .env and set a secure DB_PASSWORD
docker-compose up -d
docker-compose ps
docker-compose logs -f postgres
```

PostgreSQL is published on `localhost:5433`, and PgAdmin is available at `http://localhost:5050`.

## Connect

```bash
docker-compose exec postgres psql -U postgres -d myapp_db
```

Or connect from a host PostgreSQL client:

```bash
psql -h localhost -p 5433 -U postgres -d myapp_db
```

## Verify

```bash
docker-compose exec postgres pg_isready -U postgres
docker-compose exec postgres psql -U postgres -d myapp_db -c "SELECT version();"
docker-compose exec postgres psql -U postgres -d myapp_db -c "\\dt"
```

## Operations

```bash
make status
make logs-db
make health-check
make test
make backup
make restore BACKUP=backups/db_backup_YYYYMMDD_HHMMSS.sql
```

Use `docker-compose down` to stop services while retaining data. Use `docker-compose down -v` to remove the volume and permanently delete database data.
