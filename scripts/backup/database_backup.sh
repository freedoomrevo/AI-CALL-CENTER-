#!/bin/bash
# Aetherium Database Backup Script
# Automated PostgreSQL backup with rotation and compression

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
POSTGRES_HOST="${POSTGRES_HOST:-database}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_DB="${POSTGRES_DB:-aetherium_demo}"
POSTGRES_USER="${POSTGRES_USER:-demo_user}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="aetherium_backup_${TIMESTAMP}.sql"
COMPRESSED_FILE="${BACKUP_FILE}.gz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if PostgreSQL is accessible
log "Checking PostgreSQL connection..."
if ! pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
    error "Cannot connect to PostgreSQL at $POSTGRES_HOST:$POSTGRES_PORT"
    exit 1
fi

log "PostgreSQL connection successful"

# Create database backup
log "Starting database backup..."
if pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
    --verbose --clean --if-exists --create --format=plain \
    --file="$BACKUP_DIR/$BACKUP_FILE" 2>/dev/null; then
    log "Database backup created: $BACKUP_FILE"
else
    error "Failed to create database backup"
    exit 1
fi

# Compress backup
log "Compressing backup..."
if gzip "$BACKUP_DIR/$BACKUP_FILE"; then
    log "Backup compressed: $COMPRESSED_FILE"
else
    error "Failed to compress backup"
    exit 1
fi

# Calculate backup size
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$COMPRESSED_FILE" | cut -f1)
log "Backup size: $BACKUP_SIZE"

# Verify backup integrity
log "Verifying backup integrity..."
if gunzip -t "$BACKUP_DIR/$COMPRESSED_FILE" 2>/dev/null; then
    log "Backup integrity verified"
else
    error "Backup integrity check failed"
    exit 1
fi

# Clean up old backups
log "Cleaning up old backups (older than $RETENTION_DAYS days)..."
DELETED_COUNT=$(find "$BACKUP_DIR" -name "aetherium_backup_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete -print | wc -l)
if [ "$DELETED_COUNT" -gt 0 ]; then
    log "Deleted $DELETED_COUNT old backup(s)"
else
    log "No old backups to delete"
fi

# List current backups
log "Current backups:"
ls -lh "$BACKUP_DIR"/aetherium_backup_*.sql.gz 2>/dev/null || log "No backups found"

# Create backup metadata
cat > "$BACKUP_DIR/${TIMESTAMP}_metadata.json" << EOF
{
    "timestamp": "$TIMESTAMP",
    "database": "$POSTGRES_DB",
    "host": "$POSTGRES_HOST",
    "backup_file": "$COMPRESSED_FILE",
    "size": "$BACKUP_SIZE",
    "created_at": "$(date -Iseconds)",
    "retention_days": $RETENTION_DAYS,
    "version": "$(pg_dump --version | head -n1)"
}
EOF

log "Backup metadata created"

# Send notification (if configured)
if [ -n "${WEBHOOK_URL:-}" ]; then
    log "Sending backup notification..."
    curl -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"text\": \"✅ Aetherium database backup completed successfully\",
            \"attachments\": [{
                \"color\": \"good\",
                \"fields\": [
                    {\"title\": \"Database\", \"value\": \"$POSTGRES_DB\", \"short\": true},
                    {\"title\": \"Size\", \"value\": \"$BACKUP_SIZE\", \"short\": true},
                    {\"title\": \"Timestamp\", \"value\": \"$TIMESTAMP\", \"short\": true}
                ]
            }]
        }" 2>/dev/null || warning "Failed to send notification"
fi

log "Database backup completed successfully!"
exit 0