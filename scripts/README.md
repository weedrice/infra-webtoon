# Backup Scripts

This directory contains backup and restore scripts for the webtoon infrastructure services.

## Scripts Overview

- `pg_backup.sh` - PostgreSQL database backup
- `pg_restore.sh` - PostgreSQL database restore  
- `redis_backup.sh` - Redis data backup

## Prerequisites

- Docker Compose must be running (`docker compose up -d`)
- Required tools: `bash`, `gzip`, `zcat` (usually pre-installed)
- Services must be accessible via Docker Compose

## Usage Examples

### PostgreSQL Backup

```bash
# Basic backup (uses default environment variables)
./scripts/pg_backup.sh

# With custom environment variables
POSTGRES_DB=mydb POSTGRES_USER=myuser ./scripts/pg_backup.sh
```

**Output**: `backups/postgres/contents_YYYYMMDD_HHMMSS.dump.gz`

### PostgreSQL Restore

```bash
# Restore from backup file
./scripts/pg_restore.sh backups/postgres/contents_20240328_030000.dump.gz

# The script will:
# 1. Ask for confirmation
# 2. Clean existing objects (--clean --if-exists)
# 3. Restore the database
```

### Redis Backup

```bash
# Create Redis RDB snapshot backup
./scripts/redis_backup.sh
```

**Output**: `backups/redis/redis_YYYYMMDD_HHMMSS.rdb`

## Environment Variables

All scripts support environment variables for configuration:

### PostgreSQL Scripts
- `POSTGRES_HOST` (default: `postgres`)
- `POSTGRES_DB` (default: `contents`) 
- `POSTGRES_USER` (default: `postgres`)
- `POSTGRES_PASSWORD` (default: `dev`)

### Redis Scripts
- `REDIS_HOST` (default: `redis`)
- `REDIS_PORT` (default: `6379`)
- `REDIS_PASSWORD` (default: empty)

## Automated Backups with Cron

### Setup Crontab

```bash
# Edit crontab
crontab -e

# Add the following entries for daily backups at 3:00 AM
0 3 * * * cd /path/to/infra-webtoon && ./scripts/pg_backup.sh >> logs/backup.log 2>&1
5 3 * * * cd /path/to/infra-webtoon && ./scripts/redis_backup.sh >> logs/backup.log 2>&1
```

### Backup Retention Script

Create a cleanup script to manage old backups:

```bash
#!/bin/bash
# cleanup_old_backups.sh

# Keep only last 7 days of PostgreSQL backups
find ./backups/postgres -name "contents_*.dump.gz" -mtime +7 -delete

# Keep only last 7 days of Redis backups
find ./backups/redis -name "redis_*.rdb" -mtime +7 -delete

echo "Old backups cleaned up"
```

Add to crontab:
```bash
# Clean old backups daily at 4:00 AM
0 4 * * * cd /path/to/infra-webtoon && ./scripts/cleanup_old_backups.sh >> logs/backup.log 2>&1
```

## Windows Compatibility

These scripts are designed to work on:
- **Git Bash** (recommended for Windows)
- **WSL** (Windows Subsystem for Linux)
- **Native Unix/Linux systems**

### Git Bash Setup (Windows)

1. Install Git for Windows (includes Git Bash)
2. Open Git Bash in the project directory
3. Make scripts executable:
   ```bash
   chmod +x scripts/*.sh
   ```

## Troubleshooting

### Permission Issues
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

### Docker Compose Issues
```bash
# Ensure services are running
docker compose ps

# Check logs if services are not healthy
docker compose logs postgres
docker compose logs redis
```

### Large Backup Files
- PostgreSQL backups are compressed with gzip
- For very large databases, consider using `pg_dump` with custom format (`-Fc`)
- Monitor disk space in `backups/` directory

### Restore Issues
- Ensure the PostgreSQL service is healthy before restoring
- Check that the dump file is not corrupted
- Verify environment variables match the backup environment

## Monitoring

Check backup logs regularly:
```bash
# View recent backup logs
tail -f logs/backup.log

# Check backup file sizes
du -h backups/postgres/
du -h backups/redis/
```

## Security Notes

- Backup files may contain sensitive data - secure the `backups/` directory appropriately
- Consider encrypting backup files for production environments
- Restrict access to backup scripts and files
- Regularly test restore procedures