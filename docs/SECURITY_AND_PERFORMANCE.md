# Security, auditing, and performance (local PostgreSQL)

These controls use PostgreSQL and Docker locally; they do not depend on AWS. AWS deployment and cloud-managed encryption are intentionally out of scope.

## Schema

`init-scripts/01_schema.sql` defines `public.users`, `public.products`, and `public.orders`, including primary/foreign keys, data checks, and indexes for order lookups. Docker's PostgreSQL image runs initialization SQL only when creating a new, empty data directory. Existing named volumes are not migrated by adding this file; inspect and back up existing data, then apply an intentional migration rather than deleting the volume.

## RBAC

The optional `security/setup_roles.sql` creates the non-login group roles `lab_readonly` and `lab_app`, then grants table/sequence permissions. It does not create login accounts or store passwords. Apply it after the schema with `make security-roles`.

Create individual login roles interactively from the database administrator's `psql` session so passwords are not embedded in repository files or shell history:

```sql
CREATE ROLE reporting_login LOGIN IN ROLE lab_readonly;
\\password reporting_login
CREATE ROLE app_login LOGIN IN ROLE lab_app;
\\password app_login
```

The default-privilege grants in the script apply to future objects created by the role that ran it. Re-run the grants for other object-owner roles if the project later creates tables under a different owner. Keep the administrator account for administration; use `lab_app`-member logins for application access.

## Audit logging

`security/enable_auditing.sql` installs triggers for all three business tables. Apply it with `make audit-enable`. It captures row images for INSERT, UPDATE, and DELETE and the authenticated `session_user`; it does not record SELECT activity. Audit rows are transactional, so a failed business transaction does not leave a committed audit record. Treat the audit table as sensitive because row images can contain personal data. A database superuser or owner can modify audit records; this is change tracking, not tamper-proof compliance logging.

## Performance checks

Run `make performance` to execute read-only snapshots for table sizes, approximate row/dead-row counts, cache statistics, and index usage. Use `EXPLAIN (ANALYZE, BUFFERS)` on representative SELECT queries when investigating plans; `ANALYZE` executes the query, so use care with statements that modify data. Statistics are workload-dependent and resettable—don't remove an index solely because its scan count is currently low.

For normalized query-level statistics, PostgreSQL 16 includes `pg_stat_statements`, but it must be preloaded at server start. This is optional and is not enabled by the base Compose configuration. To enable it, add `command: ["postgres", "-c", "shared_preload_libraries=pg_stat_statements"]` to the `postgres` service, recreate/restart the container without removing the named volume, then create the extension once as administrator:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

Use a backup and planned restart before changing server startup configuration. Do not run `docker-compose down -v` to enable it.

## Encryption and secrets

The Compose `.env` file is ignored by Git. Copy `.env.example` to `.env` and replace both example passwords before starting services. Never commit `.env` or real credentials.

For encryption at rest in a local lab, store Docker's data directory/volume on a host disk protected by the operating system's disk encryption (for example BitLocker, FileVault, or LUKS). PostgreSQL's Docker volume is not automatically encrypted. File/volume copies and SQL dumps need separate protection too.

Encryption in transit requires PostgreSQL TLS certificates and client settings; it is not enabled by the default local Compose setup. The PostgreSQL host port is published on the host, so keep this lab on a trusted machine/network and do not expose it publicly without a deliberate network and TLS configuration.
