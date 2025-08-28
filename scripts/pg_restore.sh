#!/bin/bash

# PostgreSQL Restore Script
# This script restores a PostgreSQL database from a compressed dump file
# Compatible with Windows (Git Bash/WSL) and Unix systems

set -e  # Exit on any error

# Check if dump file argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <dumpfile.gz>"
    echo "Example: $0 backups/postgres/contents_20240328_030000.dump.gz"
    exit 1
fi

DUMP_FILE="$1"

# Check if dump file exists
if [ ! -f "$DUMP_FILE" ]; then
    echo "✗ Error: Dump file '$DUMP_FILE' not found!" >&2
    exit 1
fi

# Load environment variables or use defaults
POSTGRES_HOST=${POSTGRES_HOST:-postgres}
POSTGRES_DB=${POSTGRES_DB:-contents}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-dev}

# Set PGPASSWORD environment variable for authentication
export PGPASSWORD="$POSTGRES_PASSWORD"

echo "PostgreSQL Database Restore"
echo "=========================="
echo "Database: $POSTGRES_DB"
echo "Dump file: $DUMP_FILE"
echo ""

# Warning about existing connections
echo "⚠️  WARNING: This operation will restore the database."
echo "   Make sure to stop all applications that might be using the database."
echo "   Existing data will be cleaned and replaced."
echo ""

# Confirmation prompt
read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

echo ""
echo "Starting database restore..."

# Note: We skip DROP/CREATE DATABASE as it requires superuser privileges
# Instead, we rely on --clean --if-exists flags in pg_restore
echo "ℹ️  Note: Using --clean --if-exists to remove existing objects before restore"
echo "   Database '$POSTGRES_DB' will not be dropped/recreated (requires superuser)"

# Restore database using docker compose exec
# Handle both .gz and uncompressed files
if [[ "$DUMP_FILE" =~ \.gz$ ]]; then
    echo "Decompressing and restoring from gzipped dump..."
    if zcat "$DUMP_FILE" | docker compose exec -T postgres pg_restore \
        -h "$POSTGRES_HOST" \
        -U "$POSTGRES_USER" \
        -d "$POSTGRES_DB" \
        --clean \
        --if-exists \
        --no-password \
        --verbose; then
        
        echo "✓ Database restore completed successfully!"
    else
        echo "✗ Database restore failed!" >&2
        exit 1
    fi
else
    echo "Restoring from uncompressed dump..."
    if docker compose exec -T postgres pg_restore \
        -h "$POSTGRES_HOST" \
        -U "$POSTGRES_USER" \
        -d "$POSTGRES_DB" \
        --clean \
        --if-exists \
        --no-password \
        --verbose \
        < "$DUMP_FILE"; then
        
        echo "✓ Database restore completed successfully!"
    else
        echo "✗ Database restore failed!" >&2
        exit 1
    fi
fi

echo ""
echo "Restore operation finished. Please verify your data."