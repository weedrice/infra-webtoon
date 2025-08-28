#!/bin/bash

# PostgreSQL Backup Script
# This script creates a compressed PostgreSQL dump using pg_dump
# Compatible with Windows (Git Bash/WSL) and Unix systems

set -e  # Exit on any error

# Load environment variables or use defaults
POSTGRES_HOST=${POSTGRES_HOST:-postgres}
POSTGRES_DB=${POSTGRES_DB:-contents}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-dev}
COMPOSE_PROJECT=${COMPOSE_PROJECT:-infra-webtoon}

# Generate timestamp for filename (Windows compatible)
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_FILE="contents_${TIMESTAMP}.dump.gz"
BACKUP_DIR="./backups/postgres"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

echo "Starting PostgreSQL backup..."
echo "Database: $POSTGRES_DB"
echo "Output file: $BACKUP_DIR/$BACKUP_FILE"

# Create backup using docker compose exec
# Use -T to disable pseudo-tty allocation for proper piping
if docker compose exec -T postgres pg_dump \
    -h "$POSTGRES_HOST" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -Fc \
    --no-password | gzip > "$BACKUP_DIR/$BACKUP_FILE"; then
    
    echo "✓ Backup completed successfully: $BACKUP_DIR/$BACKUP_FILE"
    
    # Show file size
    if command -v du >/dev/null 2>&1; then
        SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
        echo "  File size: $SIZE"
    fi
else
    echo "✗ Backup failed!" >&2
    # Clean up failed backup file
    rm -f "$BACKUP_DIR/$BACKUP_FILE"
    exit 1
fi

# Set PGPASSWORD environment variable for pg_dump authentication
export PGPASSWORD="$POSTGRES_PASSWORD"