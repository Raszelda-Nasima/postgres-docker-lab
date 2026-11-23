#!/bin/bash
# Restore database from backup (disaster recovery)
# CAUTION: This will drop and recreate the database!

BACKUP_FILE="${1:-.}"
DB_USER="postgres"
DB_NAME="myapp_db"
CONTAINER_NAME="postgres"

if [ "$BACKUP_FILE" = "." ] || [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Usage: $0 <backup_file>"
    echo "Example: $0 ./backups/full_backup_20231120_020000.sql.gz"
    exit 1
fi

echo "[$(date)] ⚠️  Starting database RESTORE from: $BACKUP_FILE"
echo "[$(date)] This will DROP the existing database!"

read -p "Are you sure? Type 'yes' to confirm: " confirm
if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Step 1: Drop existing database
echo "[$(date)] Dropping existing database..."
docker exec "$CONTAINER_NAME" psql -U "$DB_USER" <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME;
EOF

# Step 2: Restore from backup
echo "[$(date)] Restoring data from backup..."
gunzip -c "$BACKUP_FILE" | docker exec -i "$CONTAINER_NAME" \
  psql -U "$DB_USER" -d "$DB_NAME"

echo "[$(date)] ✅ Restore completed"

# Step 3: Verify restore
echo "[$(date)] Verifying restore..."
docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" <<EOF
SELECT 'users' as table_name, COUNT(*) as row_count FROM users
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders;
EOF

echo "[$(date)] ✅ Database restore completed successfully"
