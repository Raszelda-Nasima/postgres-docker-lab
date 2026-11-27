# Quick Reference

## Start and stop

```bash
cp .env.example .env
docker-compose up -d
docker-compose ps
docker-compose logs -f postgres
docker-compose down
```

## Services

| Service | Address |
|---|---|
| PostgreSQL | `localhost:5433` (container port 5432) |
| PgAdmin | `http://localhost:5050` |

## Make shortcuts

```bash
make help
make up
make status
make logs
make test
make health-check
make backup
make restore BACKUP=path/to/backup.sql
make down
```

## Database access

```bash
docker-compose exec postgres psql -U postgres -d myapp_db
```

```sql
SELECT * FROM users;
SELECT * FROM products;
SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;
```

## Project files

- `docker-compose.yml`: local services, networking, volume, and health check
- `Makefile`: common local operations
- `init-scripts/`: database initialization SQL
- `backup-scripts/`: backup and restore scripts
- `monitoring/`: database health check
- `security/`: optional audit setup
- `docs/`: setup, architecture, and database operations guides
