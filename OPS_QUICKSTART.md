# Local PostgreSQL Operations Quick Start

## Backup and recovery

```bash
bash backup-scripts/full_backup.sh
bash backup-scripts/restore_backup.sh ./backups/full_backup_YYYYMMDD_HHMMSS.sql.gz
ls -lh backups/full_backup_*.sql.gz
```

The restore script replaces the current database, so review the target and confirm carefully.

## Monitoring and auditing

```bash
bash monitoring/check_database_health.sh
docker exec postgres_db psql -U postgres -d myapp_db -c "SELECT table_name, operation, user_name, timestamp FROM audit.table_log ORDER BY timestamp DESC LIMIT 20;"
docker exec postgres_db psql -U postgres -d myapp_db -f security/enable_auditing.sql
```

## Maintenance

```bash
docker exec postgres_db psql -U postgres -d myapp_db -c "VACUUM ANALYZE;"
docker exec postgres_db psql -U postgres -d myapp_db -c "REINDEX DATABASE myapp_db;"
```

## Guides

- [README.md](README.md) — local project overview
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) — local setup and operations
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Compose architecture
- [docs/DATABASE_OPS_AND_ADMINISTRATION.md](docs/DATABASE_OPS_AND_ADMINISTRATION.md) — database operations reference
