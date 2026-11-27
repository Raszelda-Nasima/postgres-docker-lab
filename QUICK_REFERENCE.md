# Quick Reference

## Start and stop

```bash
cp .env.example .env
# Replace both example passwords in .env
docker-compose up -d
docker-compose ps
docker-compose logs -f postgres
docker-compose down
```

## Services

| Service | Address / details |
|---|---|
| PostgreSQL | `localhost:5433` (container port 5432); Compose service `postgres`, container `postgres_db` |
| PgAdmin | `http://localhost:5050/pgadmin`; Compose service/container `pgadmin` |

## Database access

```bash
docker-compose exec postgres psql -U postgres -d myapp_db
```

Host client connection: `psql -h localhost -p 5433 -U postgres -d myapp_db`. Credentials and database name can be changed through `.env` (`DB_USER`, `DB_PASSWORD`, and `DB_NAME`).

The initialization script creates `users`, `products`, and `orders` on first initialization of an empty data volume. It does not add sample records.

```sql
SELECT * FROM public.users;
SELECT * FROM public.products;
SELECT * FROM public.orders;
SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;
```

## Makefile targets

Only the following targets are defined in the current `Makefile`:

```bash
make security-roles
make audit-enable
make performance
```

They apply optional least-privilege grants, install row-change audit triggers, and run read-only performance/statistics queries, respectively. Lifecycle, backup, restore, test, and health-check Make targets are not currently defined.

## Project files

- `docker-compose.yml`: PostgreSQL/PgAdmin services, ports, network, volume, health check, and environment configuration
- `.env.example`: required local environment-variable template
- `Makefile`: security and performance targets
- `init-scripts/01_schema.sql`: business tables, constraints, and indexes
- `backup-scripts/`: compressed backup and restore scripts (container name currently differs from Compose)
- `monitoring/`: health-check script and read-only performance SQL
- `security/`: optional roles and audit triggers
- `docs/`: deployment, architecture, database operations, and security guides
- `terraform/`: retained placeholder files only; no infrastructure resources are declared
