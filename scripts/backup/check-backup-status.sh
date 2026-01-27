#!/bin/bash

####################################
# Homelab Backup Status Checker
####################################

BACKUP_DIR="/backups/homelab"
LOG_FILE="/var/log/homelab-backup.log"
MAX_AGE_HOURS=30  # Alert if last backup is older than 30 hours

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Homelab Backup Status ==="
echo ""

# Check if backup directory exists
if [ ! -d "${BACKUP_DIR}" ]; then
    echo -e "${RED}ERROR: Backup directory not found${NC}"
    exit 1
fi

# Find latest backup
LATEST_BACKUP=$(find "${BACKUP_DIR}" -name "homelab-backup-*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)

if [ -z "${LATEST_BACKUP}" ]; then
    echo -e "${RED}ERROR: No backups found${NC}"
    exit 1
fi

# Get backup age
BACKUP_TIME=$(stat -c %Y "${LATEST_BACKUP}")
CURRENT_TIME=$(date +%s)
AGE_SECONDS=$((CURRENT_TIME - BACKUP_TIME))
AGE_HOURS=$((AGE_SECONDS / 3600))

# Get backup size
BACKUP_SIZE=$(du -h "${LATEST_BACKUP}" | cut -f1)

# Count total backups
TOTAL_BACKUPS=$(find "${BACKUP_DIR}" -name "homelab-backup-*.tar.gz" | wc -l)

# Display status
echo "Latest backup: $(basename "${LATEST_BACKUP}")"
echo "Backup age: ${AGE_HOURS} hours"
echo "Backup size: ${BACKUP_SIZE}"
echo "Total backups: ${TOTAL_BACKUPS}"
echo ""

# Check if backup is too old
if [ "${AGE_HOURS}" -gt "${MAX_AGE_HOURS}" ]; then
    echo -e "${RED}WARNING: Latest backup is older than ${MAX_AGE_HOURS} hours!${NC}"
    echo "Check systemd timer: sudo systemctl status homelab-backup.timer"
    exit 1
else
    echo -e "${GREEN}Status: Backups are current${NC}"
fi

# Check last 3 log entries
echo ""
echo "Recent backup log entries:"
tail -n 3 "${LOG_FILE}"