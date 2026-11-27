# Security, Auditing, and Performance (Local PostgreSQL)

These controls use PostgreSQL and Docker locally. The repository does not configure AWS or other cloud infrastructure.

## Schema and constraints

`init-scripts/01_schema.sql` creates `public.users`, `public.products`, and `public.orders`, with identity primary keys, unique user fields, foreign keys, data checks, timestamps, and indexes for order lookups. The script runs only when PostgreSQL initializes an empty data volume and does not seed sample records.

## Least-privilege roles

Run the optional grants after the schema exists:

```bash
make security-roles
```

`security/setup_roles.sql` creates non-login group roles `lab_readonly` and `lab_app`; it grants read access to the former and table/sequence access to the latter. It does not create login roles or embed passwords. The `ALTER DEFAULT PRIVILEGES` grants affect future objects created by the role that runs the script, so apply equivalent defaults for any other object-owner roles as needed.

Create individual login roles interactively from an administrator's `psql` session, then set passwords using psql's password prompt:

```sql
CREATE ROLE reporting_login LOGIN IN ROLE lab_readonly;
\\password reporting_login
CREATE ROLE app_login LOGIN IN ROLE lab_app;
\\password app_login
```

## Row-change auditing

Enable the optional triggers after the schema exists:

```bash
make audit-enable
```

`security/enable_auditing.sql` creates the `audit` schema and `audit.table_log`, then installs AFTER triggers on `public.users`, `public.products`, and `public.orders`. It records INSERT, UPDATE, and DELETE operations, including old/new row JSON where applicable and the session user. It does not audit reads. Audit entries are written in the transaction of the change, so a rolled-back change does not leave a committed audit row.

## Performance snapshots

```bash
make performance
```

This executes the read-only statements in `monitoring/performance.sql`: database size, estimated live/dead rows, cache hit ratio, and index statistics. It needs no additional service or extension. Statistics are workload-dependent and may reset after server restarts or manual resets. Use `EXPLAIN (ANALYZE, BUFFERS)` for representative query-plan investigation.

The Compose configuration does not preload `pg_stat_statements` or enable query-level statistics. Enabling it requires PostgreSQL startup configuration and a planned restart; it is not part of the default lab.

## Secrets, encryption, and network exposure

Copy `.env.example` to `.env`, replace both example passwords with unique values, and never commit `.env` or real credentials. Compose requires `DB_PASSWORD`, `PGADMIN_DEFAULT_EMAIL`, and `PGADMIN_DEFAULT_PASSWORD`; database user/name default to `postgres` and `myapp_db`.

PostgreSQL TLS is not configured by default. The database port is published on the host as 5433, so keep the lab on a trusted host/network and restrict access as needed. PostgreSQL does not encrypt the Docker volume itself; use host/storage encryption and protect backup files with appropriate access controls.
