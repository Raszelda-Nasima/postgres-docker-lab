# 📋 DATABASE OPS QUICK START

This project demonstrates **production-grade database operations and administration** skills.

## Quick Commands for Systems Engineers

### 🔄 Backups & Disaster Recovery

```bash
# Full backup (creates compressed SQL dump)
bash backup-scripts/full_backup.sh
# Output: backups/full_backup_20231120_020000.sql.gz

# Restore from backup (use with caution!)
bash backup-scripts/restore_backup.sh ./backups/full_backup_20231120_020000.sql.gz

# View available backups
ls -lh backups/full_backup_*.sql.gz
```

### 📊 Database Monitoring

```bash
# Full health check (connections, sizes, indexes, performance)
bash monitoring/check_database_health.sh

# View audit log (who changed what, when)
docker exec postgres psql -U postgres -d myapp_db -c \
  "SELECT table_name, operation, user_name, timestamp FROM audit.table_log ORDER BY timestamp DESC LIMIT 20;"
```

### 🔐 Security & Access Control

```bash
# Enable audit logging
docker exec postgres psql -U postgres -d myapp_db -f security/enable_auditing.sql

# List current roles and permissions
docker exec postgres psql -U postgres -c "\du+"

# Create read-only reporting user
docker exec postgres psql -U postgres -d myapp_db <<EOF
CREATE ROLE reporting_user LOGIN PASSWORD 'ReadOnlyPass123!';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO reporting_user;
EOF
```

### 🔧 Maintenance

```bash
# Run maintenance (vacuum, analyze, reindex)
docker exec postgres psql -U postgres -d myapp_db <<EOF
VACUUM ANALYZE;
REINDEX DATABASE myapp_db;
EOF

# Check slow queries (> 100ms)
docker exec postgres psql -U postgres -d myapp_db -c \
  "SELECT query, calls, mean_time FROM pg_stat_statements WHERE mean_time > 100 ORDER BY mean_time DESC LIMIT 5;"
```

## Documentation

- **[DATABASE_OPS_AND_ADMINISTRATION.md](docs/DATABASE_OPS_AND_ADMINISTRATION.md)** - Complete ops guide with 6 sections
  - Backup & disaster recovery procedures
  - Performance monitoring & optimization
  - Security, access control & auditing
  - Disaster recovery runbooks
  - Maintenance tasks
  - Monitoring setup

- **[SYSTEM_ARCHITECTURE_DETAILED.md](docs/SYSTEM_ARCHITECTURE_DETAILED.md)** - Full system design
  - Docker orchestration
  - Database schema & relationships
  - User interaction flow
  - Data persistence
  - Constraint protection

- **[README.md](README.md)** - Project overview

## Systems Engineering Skills Demonstrated

✅ **Backup & Disaster Recovery**
  - Automated backup strategies with 7-day retention
  - Point-in-time recovery procedures
  - RPO/RTO calculations
  - Backup verification

✅ **Performance Monitoring**
  - Real-time health checks
  - Slow query detection
  - Cache hit ratio analysis
  - Query plan optimization (EXPLAIN ANALYZE)

✅ **Security & Access Control**
  - Role-based access control (RBAC)
  - Audit logging with triggers
  - Encryption strategies
  - Principle of least privilege

✅ **Operational Excellence**
  - Disaster recovery runbooks
  - Maintenance schedules
  - Capacity planning
  - Monitoring and alerting strategies

## Directory Structure

```
postgres-docker-lab/
├── backup-scripts/           # Operational backup scripts
│   ├── full_backup.sh        # Automated full backup
│   └── restore_backup.sh     # Restore from backup
├── monitoring/               # Health monitoring scripts
│   └── check_database_health.sh  # Comprehensive health checks
├── security/                 # Security & audit scripts
│   └── enable_auditing.sql   # Audit logging setup
├── docs/
│   ├── DATABASE_OPS_AND_ADMINISTRATION.md  # Complete ops guide
│   └── SYSTEM_ARCHITECTURE_DETAILED.md     # System design
└── docker-compose.yml        # Container orchestration
```

## Ready for Production?

This project demonstrates the operational skills needed for production systems:

- ✅ **Testable backups** - `restore_backup.sh` enables disaster recovery testing
- ✅ **Monitoring in place** - `check_database_health.sh` enables proactive alerting
- ✅ **Security hardened** - Audit logging tracks all changes
- ✅ **Documented runbooks** - Disaster recovery procedures are clear
- ✅ **Automated maintenance** - Backup scripts can be scheduled with cron

A systems engineer's job isn't just building systems—it's keeping them running safely and reliably. This project shows you understand that responsibility.

---

**Portfolio Note:** This project demonstrates the bridge between application development and systems operations—a valuable skill for any DevOps or Systems Engineer role.
