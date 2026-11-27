#!/usr/bin/env bash
# Host cron entry point. Logs output and prevents overlapping scheduled backups.

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR"

# Cron has a minimal PATH; set one that includes common Docker installation paths.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Keep all scheduled output, including errors, for operational review.
exec >> "$LOG_DIR/backup-cron.log" 2>&1

echo "[$(date --iso-8601=seconds)] Scheduled backup job started"

if ! command -v flock >/dev/null 2>&1; then
  echo "❌ flock is required to prevent concurrent scheduled backups" >&2
  exit 1
fi

exec 9>"$LOG_DIR/backup.lock"
if ! flock -n 9; then
  echo "[$(date --iso-8601=seconds)] Another backup is already running; skipping this run"
  exit 0
fi

"$SCRIPT_DIR/full_backup.sh"
