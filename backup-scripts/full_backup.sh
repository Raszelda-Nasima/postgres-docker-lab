#!/bin/bash
# Full database backup using pg_dump
# Systems engineer: handles schema + data, compression, versioning

set -e  # Exit on error

BACKUP_DIR="./backups"
DB_NAME="myapp_db"
DB_USER="postgres"
CONTAINER_NAME="postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/full_backup_${TIMESTAMP}.sql.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting full database backup..."
echo "[$(date)] Backup file: $BACKUP_FILE"

# Run pg_dump through Docker
if docker ps | grep -q "$CONTAINER_NAME"; then
    # Use pg_dump to create backup
    docker exec "$CONTAINER_NAME" pg_dump \
      -U "$DB_USER" \
      "$DB_NAME" | gzip > "$BACKUP_FILE"
    
    # Verify backup was created
    if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
        SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        echo "[$(date)] ✅ Backup succeeded: $BACKUP_FILE ($SIZE)"
        
        # Keep only last 7 backups (retention policy)
        echo "[$(date)] Cleaning up old backups (keeping last 7)..."
        ls -1t "$BACKUP_DIR"/full_backup_*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm 2>/dev/null || true
        
        echo "[$(date)] Backup process completed successfully"
        exit 0
    else
        echo "[$(date)] ❌ Backup file is empty!"
        exit 1
    fi
else
    echo "[$(date)] ❌ Container '$CONTAINER_NAME' is not running!"
    exit 1
fi
