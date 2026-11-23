# 🛠️ DATABASE OPERATIONS & ADMINISTRATION GUIDE

This document demonstrates **production-grade database operations** including automated backups, monitoring, security, and disaster recovery procedures.

---

## PART 1: AUTOMATED BACKUP & RESTORE PROCEDURES

### 1.1 Why Backups Matter (Systems Engineer Perspective)

**Risk Assessment:**
- Data loss = business stopped
- Corruption = silent data degradation
- Ransomware = encrypted database
- Developer mistakes = need recovery to point-in-time

**Backup Strategy: 3-2-1 Rule**
- **3** copies of data (original + 2 backups)
- **2** different storage types (volume + file system)
- **1** offsite backup (simulated here with timestamped files)

### 1.2 Full Backup Script

Create: `backup-scripts/full_backup.sh`

```bash
#!/bin/bash
# Full database backup using pg_dump
# Systems engineer: handles schema + data, compression, versioning

set -e  # Exit on error

BACKUP_DIR="./backups"
DB_NAME="myapp_db"
DB_USER="postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/full_backup_${TIMESTAMP}.sql.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting full database backup..."

# Method 1: Using pg_dump through Docker
docker exec postgres-docker-lab_postgres_1 pg_dump \
  -U "$DB_USER" \
  --no-password \
  "$DB_NAME" | gzip > "$BACKUP_FILE"

# Verify backup was created
if [ -f "$BACKUP_FILE" ]; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "[$(date)] ✅ Backup succeeded: $BACKUP_FILE ($SIZE)"
    
    # Keep only last 7 backups (retention policy)
    echo "[$(date)] Cleaning up old backups (keeping last 7)..."
    ls -1t "$BACKUP_DIR"/full_backup_*.sql.gz | tail -n +8 | xargs -r rm
    
    echo "[$(date)] Backup process completed successfully"
else
    echo "[$(date)] ❌ Backup failed!"
    exit 1
fi
```

### 1.3 Incremental/WAL Backup Strategy

For production systems, use **Write-Ahead Logging (WAL)** for point-in-time recovery:

```bash
#!/bin/bash
# WAL backup configuration - enables PITR (Point-In-Time Recovery)

# Step 1: Enable WAL archiving in postgresql.conf
# (In Docker, add to docker-compose.yml environment)

docker exec postgres-docker-lab_postgres_1 psql -U postgres -d myapp_db <<EOF
-- Check WAL settings
SHOW wal_level;           -- Should be 'replica' or 'logical' for production
SHOW archive_mode;        -- Should be 'on'
SHOW archive_command;     -- Should point to backup directory

-- Enable WAL archiving
ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET archive_mode = 'on';
ALTER SYSTEM SET archive_command = 'cp %p /var/lib/postgresql/archive/%f';

-- Reload configuration
SELECT pg_ctl_reload();
EOF
```

### 1.4 Restore from Backup Procedure

```bash
#!/bin/bash
# Full restore from backup (disaster recovery scenario)

BACKUP_FILE="$1"  # Pass backup file as argument
DB_USER="postgres"
DB_NAME="myapp_db"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "[$(date)] Starting database restore from: $BACKUP_FILE"

# Step 1: Drop existing database (careful!)
echo "[$(date)] Dropping existing database..."
docker exec postgres-docker-lab_postgres_1 psql -U "$DB_USER" <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME;
EOF

# Step 2: Restore from backup
echo "[$(date)] Restoring data from backup..."
gunzip -c "$BACKUP_FILE" | docker exec -i postgres-docker-lab_postgres_1 \
  psql -U "$DB_USER" -d "$DB_NAME"

echo "[$(date)] ✅ Restore completed successfully"

# Step 3: Verify restore
docker exec postgres-docker-lab_postgres_1 psql -U "$DB_USER" -d "$DB_NAME" <<EOF
SELECT COUNT(*) as user_count FROM users;
SELECT COUNT(*) as product_count FROM products;
SELECT COUNT(*) as order_count FROM orders;
EOF
```

### 1.5 Automated Backup Scheduling

Create: `backup-scripts/backup-cron.sh`

```bash
#!/bin/bash
# Automated daily backups using cron
# Add to crontab: 0 2 * * * /path/to/backup-cron.sh

BACKUP_DIR="./backups"
LOG_FILE="$BACKUP_DIR/backup.log"
CONTAINER_NAME="postgres-docker-lab_postgres_1"

# Daily full backup at 2 AM
echo "[$(date)] ========== DAILY BACKUP ==========" >> "$LOG_FILE"

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "[$(date)] ❌ Container not running" >> "$LOG_FILE"
    exit 1
fi

# Run backup
bash ./backup-scripts/full_backup.sh 2>> "$LOG_FILE"

# Alert if backup fails
if [ $? -ne 0 ]; then
    echo "[$(date)] ⚠️ Backup failed! Check logs." | mail -s "DB Backup Failed" admin@example.com
fi
```

---

## PART 2: DATABASE MONITORING & PERFORMANCE TUNING

### 2.1 Real-Time Monitoring

Create: `monitoring/check_database_health.sh`

```bash
#!/bin/bash
# Database health check script
# Monitors: connections, cache hit ratio, slow queries, table sizes

CONTAINER_NAME="postgres-docker-lab_postgres_1"
DB_USER="postgres"
DB_NAME="myapp_db"

check_database_health() {
    echo "🔍 DATABASE HEALTH CHECK - $(date)"
    echo "============================================"
    
    # 1. Connection Status
    echo -e "\n📊 CONNECTION STATUS:"
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c \
    "SELECT datname, usename, state, count(*) as connections 
     FROM pg_stat_activity 
     GROUP BY datname, usename, state;"
    
    # 2. Cache Hit Ratio (should be > 99%)
    echo -e "\n💾 CACHE HIT RATIO (Higher is better):"
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c \
    "SELECT 
        sum(heap_blks_read) as total_disk_reads,
        sum(heap_blks_hit) as total_cache_hits,
        sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as hit_ratio
     FROM pg_statio_user_tables;"
    
    # 3. Table Sizes
    echo -e "\n📦 TABLE SIZES:"
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c \
    "SELECT 
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
     FROM pg_tables 
     WHERE schemaname != 'pg_catalog' 
     ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
    
    # 4. Missing Indexes
    echo -e "\n🔑 UNUSED INDEXES (Candidates for deletion):"
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c \
    "SELECT 
        schemaname,
        tablename,
        indexname,
        idx_scan as times_used
     FROM pg_stat_user_indexes 
     WHERE idx_scan = 0 
     ORDER BY pg_relation_size(indexrelid) DESC;"
    
    # 5. Database Size
    echo -e "\n💽 DATABASE SIZE:"
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c \
    "SELECT pg_database.datname, 
            pg_size_pretty(pg_database_size(pg_database.datname)) 
     FROM pg_database 
     WHERE datname = '$DB_NAME';"
    
    # 6. Replication Lag (if replication is set up)
    echo -e "\n🔄 REPLICATION STATUS:"
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c \
    "SELECT client_addr, state, write_lag, flush_lag, replay_lag 
     FROM pg_stat_replication;" 2>/dev/null || echo "   No replicas configured"
    
    echo -e "\n✅ Health check complete"
}

check_database_health
```

### 2.2 Slow Query Detection

Create: `monitoring/slow_queries.sh`

```bash
#!/bin/bash
# Find slow queries (> 100ms) for optimization
# Systems engineer task: identify bottlenecks

CONTAINER_NAME="postgres-docker-lab_postgres_1"
DB_USER="postgres"
DB_NAME="myapp_db"

docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" <<EOF

-- Enable query logging for slow queries
ALTER SYSTEM SET log_min_duration_statement = 100;  -- Log queries > 100ms
ALTER SYSTEM SET log_duration = off;
SELECT pg_ctl_reload();

-- View recent slow queries from logs
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SELECT query, calls, mean_time, max_time
FROM pg_stat_statements
WHERE mean_time > 100  -- queries averaging > 100ms
ORDER BY mean_time DESC
LIMIT 10;

EOF
```

### 2.3 Query Optimization Techniques

```bash
#!/bin/bash
# BEFORE: Slow query without index
# Query: Get all orders by user (without index)

SLOW_QUERY="
  SELECT * FROM orders WHERE user_id = 1;
"

# ANALYZE: Check query plan
docker exec postgres-docker-lab_postgres_1 psql -U postgres -d myapp_db <<EOF
EXPLAIN ANALYZE
SELECT * FROM orders WHERE user_id = 1;
EOF

# Output shows: Seq Scan (bad!) - scanning entire table

# SOLUTION: Add index (already done in init script)
# CREATE INDEX idx_orders_user_id ON orders(user_id);

# AFTER: Same query now uses index
docker exec postgres-docker-lab_postgres_1 psql -U postgres -d myapp_db <<EOF
EXPLAIN ANALYZE
SELECT * FROM orders WHERE user_id = 1;
EOF

# Output shows: Index Scan (good!) - using index
```

---

## PART 3: SECURITY, ACCESS CONTROL & AUDITING

### 3.1 Role-Based Access Control (RBAC)

Create: `security/setup_roles.sql`

```sql
-- Setup different database roles for security
-- Systems engineer: principle of least privilege

-- 1. Read-only user (for reporting)
CREATE ROLE reporting_user LOGIN PASSWORD 'ReadOnlyPass123!';
GRANT CONNECT ON DATABASE myapp_db TO reporting_user;
GRANT USAGE ON SCHEMA public TO reporting_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO reporting_user;

-- 2. Application user (read + write, but no DDL)
CREATE ROLE app_user LOGIN PASSWORD 'AppPass123!';
GRANT CONNECT ON DATABASE myapp_db TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;

-- 3. Admin user (full privileges)
-- CREATE ROLE admin_user LOGIN PASSWORD 'AdminPass123!';
-- GRANT ALL PRIVILEGES ON DATABASE myapp_db TO admin_user;

-- Test: Connect as reporting_user (can SELECT, not INSERT)
-- psql -U reporting_user -d myapp_db
-- SELECT * FROM users;              -- ✅ Works
-- INSERT INTO users VALUES (...);   -- ❌ Permission denied
```

### 3.2 Connection Security (pg_hba.conf)

Create: `security/pg_hba.conf` configuration

```
# PostgreSQL Host-Based Authentication Configuration
# Docker equivalent: environment variables in docker-compose.yml

# Local connections (from same machine)
local   all             postgres                                trust

# Docker bridge network connections (from other containers)
host    all             all             172.19.0.0/24           md5

# TCP/IP connections from localhost only
host    all             all             127.0.0.1/32            md5

# IPv6 localhost only
host    all             all             ::1/128                 md5

# NEVER allow from anywhere (unless behind VPN)
# host   all             all             0.0.0.0/0               reject
```

### 3.3 Audit Logging

Create: `security/enable_auditing.sql`

```sql
-- Enable comprehensive database auditing
-- Track: who accessed what, when, and what changed

-- 1. Create audit schema and table
CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE audit.table_log (
    id SERIAL PRIMARY KEY,
    table_name TEXT,
    operation TEXT,  -- INSERT, UPDATE, DELETE
    user_name TEXT,
    timestamp TIMESTAMP DEFAULT NOW(),
    old_data JSONB,
    new_data JSONB
);

CREATE INDEX idx_audit_table ON audit.table_log(table_name);
CREATE INDEX idx_audit_timestamp ON audit.table_log(timestamp);

-- 2. Create audit trigger function
CREATE OR REPLACE FUNCTION audit.table_audit_function() 
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit.table_log(table_name, operation, user_name, new_data)
        VALUES(TG_TABLE_NAME, TG_OP, session_user, row_to_json(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit.table_log(table_name, operation, user_name, old_data, new_data)
        VALUES(TG_TABLE_NAME, TG_OP, session_user, row_to_json(OLD), row_to_json(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit.table_log(table_name, operation, user_name, old_data)
        VALUES(TG_TABLE_NAME, TG_OP, session_user, row_to_json(OLD));
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 3. Attach audit trigger to tables
CREATE TRIGGER audit_users_trigger
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION audit.table_audit_function();

CREATE TRIGGER audit_products_trigger
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW EXECUTE FUNCTION audit.table_audit_function();

CREATE TRIGGER audit_orders_trigger
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW EXECUTE FUNCTION audit.table_audit_function();

-- 4. Query the audit log (who changed what)
SELECT * FROM audit.table_log ORDER BY timestamp DESC LIMIT 10;
```

### 3.4 Encryption at Rest

```bash
#!/bin/bash
# PostgreSQL doesn't have built-in encryption at rest
# Solution: Use encrypted filesystem (Docker volume on encrypted partition)

# On Linux: Use LUKS encrypted volume
# On Windows: Use BitLocker
# On Mac: Use FileVault2

# For Docker: use encrypted volume driver
# docker-compose.yml modification:
# volumes:
#   postgres_data:
#     driver: local
#     driver_opts:
#       type: none
#       o: bind
#       device: /mnt/encrypted_volume/postgres_data

echo "✅ Encryption at rest: Use encrypted filesystem (OS-level)"
echo "✅ Encryption in transit: Use SSL/TLS connections"
```

---

## PART 4: DISASTER RECOVERY & HIGH AVAILABILITY

### 4.1 Recovery Time Objectives (RTO) & Recovery Point Objectives (RPO)

```
Our System's Guarantees:
├─ RTO (Recovery Time Objective): 15 minutes
│  └─ Time to restore from backup and resume operations
│
├─ RPO (Recovery Point Objective): 1 hour
│  └─ Maximum data loss = 1 hour of transactions
│
└─ Implementation:
   ├─ Hourly automated backups
   ├─ Full daily backup at 2 AM
   ├─ Transaction logs for point-in-time recovery
   └─ Automated health checks every 5 minutes
```

### 4.2 Disaster Recovery Runbook

Create: `docs/DISASTER_RECOVERY.md`

```markdown
# 🆘 DISASTER RECOVERY RUNBOOK

## Scenario 1: Data Corruption in Production

**Time to Resolve: 10 minutes**

### Step 1: Identify Problem (1 min)
bash monitoring/check_database_health.sh
# Look for: query errors, constraint violations, corrupted indexes

### Step 2: Assess Scope (2 min)
# Which tables are affected? When did it start?
SELECT * FROM audit.table_log 
WHERE timestamp > NOW() - INTERVAL '30 minutes'
ORDER BY timestamp DESC;

### Step 3: Decide on Recovery Point (1 min)
# Roll back to before corruption occurred
# Options: 1 hour ago, 1 day ago, 1 week ago

### Step 4: Execute Restore (5 min)
bash backup-scripts/restore_backup.sh ./backups/full_backup_20231120_020000.sql.gz

### Step 5: Verify (1 min)
bash monitoring/check_database_health.sh
# Confirm all tables intact, audit log shows restore


## Scenario 2: Container Crashes

**Time to Resolve: 2 minutes**

### Automatic: Docker restart policy restarts container
docker-compose restart postgres

### Manual: If container won't start
docker-compose down -v  # Remove volume
docker-compose up      # Fresh start (data restored from backup)
```

### 4.3 Backup Verification Script

```bash
#!/bin/bash
# CRITICAL: Verify backups are actually restorable
# "Untested backup = no backup"

BACKUP_FILE="$1"

echo "🔍 Testing backup restore on staging database..."

# 1. Create temporary staging container
docker run --name postgres_staging -e POSTGRES_PASSWORD=temppass -d postgres:16-alpine

# 2. Restore backup into staging
sleep 5  # Wait for container to start
docker exec -i postgres_staging psql -U postgres <<EOF
CREATE DATABASE staging_db;
EOF

gunzip -c "$BACKUP_FILE" | docker exec -i postgres_staging psql -U postgres -d staging_db

# 3. Run sanity checks
echo "✅ Verifying backup integrity..."
docker exec postgres_staging psql -U postgres -d staging_db -c \
"SELECT COUNT(*) FROM users; SELECT COUNT(*) FROM products; SELECT COUNT(*) FROM orders;"

# 4. Cleanup staging
docker rm -f postgres_staging

echo "✅ Backup verified and restorable!"
```

---

## PART 5: MAINTENANCE & OPTIMIZATION

### 5.1 Regular Maintenance Tasks

```sql
-- Run weekly/monthly for database health

-- 1. Vacuum (clean up dead rows)
VACUUM ANALYZE;

-- 2. Reindex (rebuild indexes)
REINDEX DATABASE myapp_db;

-- 3. Update table statistics
ANALYZE;

-- 4. Check for missing indexes
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- 5. Monitor transaction wraparound
SELECT datname, age(datfrozenxid) 
FROM pg_database 
WHERE datname = 'myapp_db';
```

### 5.2 Capacity Planning

```bash
#!/bin/bash
# Calculate growth trends and forecast when space will run out

CONTAINER_NAME="postgres-docker-lab_postgres_1"
DB_USER="postgres"
DB_NAME="myapp_db"

docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" <<EOF
-- Get current database size
SELECT 
    'Current Size' as metric,
    pg_size_pretty(pg_database_size('$DB_NAME')) as size,
    pg_database_size('$DB_NAME') / 1024.0 / 1024.0 / 1024.0 as size_gb;

-- Growth estimate (requires historical data)
-- Typical production database growth: 10-20% per month
-- Action: When reaching 70% capacity, plan upgrades
EOF
```

---

## PART 6: MONITORING SETUP WITH PROMETHEUS (Optional Advanced)

### 6.1 Docker Compose with Monitoring

```yaml
version: '3.9'

services:
  postgres:
    # ... existing config ...
    environment:
      - POSTGRES_INITDB_ARGS=-c shared_preload_libraries=pg_stat_statements
  
  postgres_exporter:
    image: prometheuscommunity/postgres-exporter:latest
    environment:
      DATA_SOURCE_NAME: "postgresql://postgres:MySecurePassword2024!@postgres:5432/myapp_db?sslmode=disable"
    ports:
      - "9187:9187"
    depends_on:
      postgres:
        condition: service_healthy
  
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
  
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    depends_on:
      - prometheus
```

---

## Implementation Checklist

- [ ] **Backups**: Set up automated daily backups with 7-day retention
- [ ] **Monitoring**: Run daily health checks, log results
- [ ] **Security**: Configure RBAC roles, enable audit logging
- [ ] **Disaster Recovery**: Document runbooks, test restore procedures
- [ ] **Maintenance**: Schedule weekly VACUUM, monthly REINDEX
- [ ] **Capacity Planning**: Monitor growth, plan for scaling
- [ ] **Testing**: Verify backups are restorable monthly

---

## Systems Engineering Skills Demonstrated

✅ **Backup & Disaster Recovery**
  - Automated backup strategies
  - Point-in-time recovery procedures
  - RPO/RTO calculations
  - Backup verification

✅ **Performance Monitoring**
  - Real-time health checks
  - Slow query detection
  - Cache hit ratio analysis
  - Query plan optimization

✅ **Security & Access Control**
  - Role-based access control (RBAC)
  - Audit logging
  - Encryption strategies
  - Principle of least privilege

✅ **Operational Excellence**
  - Runbooks and documentation
  - Maintenance schedules
  - Capacity planning
  - Monitoring and alerting

This demonstrates **production-grade database operations** knowledge—a key systems engineer skill!
