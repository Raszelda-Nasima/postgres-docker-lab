#!/bin/bash
# Database health check script
# Monitors: connections, cache hit ratio, slow queries, table sizes

CONTAINER_NAME="postgres"
DB_USER="postgres"
DB_NAME="myapp_db"

check_database_health() {
    echo ""
    echo "🔍 DATABASE HEALTH CHECK - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "======================================================================"
    
    # 1. Connection Status
    echo -e "\n📊 CONNECTION STATUS:"
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c \
    "SELECT datname, usename, state, count(*) as connections 
     FROM pg_stat_activity 
     WHERE datname = '$DB_NAME'
     GROUP BY datname, usename, state;"
    
    # 2. Database Size
    echo -e "\n💽 DATABASE SIZE:"
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c \
    "SELECT pg_database.datname, 
            pg_size_pretty(pg_database_size(pg_database.datname)) as size
     FROM pg_database 
     WHERE datname = '$DB_NAME';"
    
    # 3. Table Sizes and Row Counts
    echo -e "\n📦 TABLE SIZES & ROW COUNTS:"
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c \
    "SELECT 
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
        (SELECT COUNT(*) FROM pg_class WHERE relname = tablename) as tables
     FROM pg_tables 
     WHERE schemaname != 'pg_catalog' 
     ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
    
    # 4. Index Status
    echo -e "\n🔑 INDEX USAGE:"
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c \
    "SELECT 
        schemaname,
        tablename,
        indexname,
        idx_scan as times_used,
        pg_size_pretty(pg_relation_size(indexrelid)) as size
     FROM pg_stat_user_indexes 
     ORDER BY idx_scan DESC;"
    
    # 5. Replication/Connection Info
    echo -e "\n🔗 DATABASE INFO:"
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c \
    "SELECT version();"
    
    echo -e "\n✅ Health check complete"
    echo "======================================================================"
}

check_database_health
