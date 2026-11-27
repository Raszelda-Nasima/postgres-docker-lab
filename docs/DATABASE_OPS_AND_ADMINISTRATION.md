# PostgreSQL Database Operations

This guide documents the local Docker Compose lab. Database security and performance features are PostgreSQL-based and independent of AWS.

## Database schema

The initial local schema is in `init-scripts/01_schema.sql`: `users`, `products`, and `orders`, with constraints, foreign keys, and order lookup indexes. The Docker PostgreSQL entrypoint runs it only when the data volume is empty. Existing volumes are preserved; do not remove them to apply schema changes. Back up first and use a deliberate migration for an existing database.

## Optional security setup

Apply role grants and row-change auditing after the schema is available:

```bash
make security-roles
make audit-enable
```

These scripts do not create login users with hard-coded passwords. Follow [Security, auditing, and performance](SECURITY_AND_PERFORMANCE.md#rbac) to provision login accounts safely and understand the audit scope. Audit triggers cover INSERT/UPDATE/DELETE on users, products, and orders; they do not record reads.

## Performance checks

```bash
make performance
```

This runs read-only PostgreSQL statistics queries without requiring extra services or extensions. Use `EXPLAIN (ANALYZE, BUFFERS)` to examine a representative query plan. Query-level `pg_stat_statements` is optional and requires a PostgreSQL restart to preload; see the security/performance guide before enabling it.

## Backups

Back up before applying schema, security, or server configuration changes:

```bash
make backup
```

The backup is written under the ignored `backups/` directory. Preserve it securely outside the repository. Never use `docker-compose down -v` as a migration method; it deletes the database volume.

## Encryption and local secrets

Use a private `.env` file based on `.env.example`, replace its example credentials, and keep it out of version control. The local Docker volume is not encrypted by PostgreSQL; protect the host disk and backup files with OS-level encryption/access controls. TLS is not enabled by default. See [Security, auditing, and performance](SECURITY_AND_PERFORMANCE.md#encryption-and-secrets).
