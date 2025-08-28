#!/bin/bash

# Redis Backup Script
# This script creates a Redis RDB snapshot backup
# Compatible with Windows (Git Bash/WSL) and Unix systems

set -e  # Exit on any error

# Load environment variables or use defaults
REDIS_HOST=${REDIS_HOST:-redis}
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASSWORD=${REDIS_PASSWORD:-}  # Empty by default

# Generate timestamp for filename (Windows compatible)
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_FILE="redis_${TIMESTAMP}.rdb"
BACKUP_DIR="./backups/redis"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

echo "Starting Redis backup..."
echo "Redis host: $REDIS_HOST:$REDIS_PORT"
echo "Output file: $BACKUP_DIR/$BACKUP_FILE"

# Build redis-cli command with optional password
REDIS_CLI_CMD="redis-cli -h $REDIS_HOST -p $REDIS_PORT"
if [ -n "$REDIS_PASSWORD" ]; then
    REDIS_CLI_CMD="$REDIS_CLI_CMD -a $REDIS_PASSWORD"
fi

# Force a BGSAVE to ensure we have a recent snapshot
echo "Triggering background save..."
if docker compose exec -T redis $REDIS_CLI_CMD BGSAVE; then
    echo "✓ Background save initiated"
else
    echo "✗ Failed to initiate background save!" >&2
    exit 1
fi

# Wait for background save to complete
echo "Waiting for background save to complete..."
while true; do
    # Check if background save is still in progress
    if docker compose exec -T redis $REDIS_CLI_CMD LASTSAVE | grep -q "$(docker compose exec -T redis $REDIS_CLI_CMD LASTSAVE)"; then
        sleep 1
        echo -n "."
    else
        break
    fi
    
    # Timeout after 30 seconds
    if [ ${SECONDS:-0} -gt 30 ]; then
        echo ""
        echo "⚠️  Warning: Background save taking longer than expected"
        break
    fi
done
echo ""

# Copy the RDB file from container
echo "Copying RDB file from Redis container..."
if docker compose exec -T redis cat /data/dump.rdb > "$BACKUP_DIR/$BACKUP_FILE"; then
    echo "✓ Redis backup completed successfully: $BACKUP_DIR/$BACKUP_FILE"
    
    # Show file size
    if command -v du >/dev/null 2>&1; then
        SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
        echo "  File size: $SIZE"
    fi
    
    # Show Redis info
    echo ""
    echo "Redis Info:"
    docker compose exec -T redis $REDIS_CLI_CMD INFO memory | grep -E "used_memory_human|used_memory_peak_human" || true
    docker compose exec -T redis $REDIS_CLI_CMD DBSIZE | sed 's/^/  Keys: /' || true
    
else
    echo "✗ Redis backup failed!" >&2
    # Clean up failed backup file
    rm -f "$BACKUP_DIR/$BACKUP_FILE"
    exit 1
fi