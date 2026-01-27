#!/bin/bash

####################################
# Homelab Backup Script
####################################
# 
# Purpose: Backup all persistent service data
# Schedule: Runs daily at 2 AM via systemd timer
# Retention: 7 days (configurable)
#
####################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

####################################
# Configuration
####################################

BACKUP_SOURCE="/srv"
BACKUP_DEST="/backups/homelab"
BACKUP_RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="homelab-backup-${TIMESTAMP}.tar.gz"
LOG_FILE="/var/log/homelab-backup.log"

####################################
# Logging Function
####################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

####################################
# Pre-flight Checks
####################################

log "=== Homelab Backup Started ==="

# Check if source directory exists
if [ ! -d "${BACKUP_SOURCE}" ]; then
    log "ERROR: Source directory ${BACKUP_SOURCE} does not exist"
    exit 1
fi

# Create backup destination if it doesn't exist
if [ ! -d "${BACKUP_DEST}" ]; then
    log "Creating backup destination: ${BACKUP_DEST}"
    sudo mkdir -p "${BACKUP_DEST}"
    sudo chown "${USER}:${USER}" "${BACKUP_DEST}"
fi

# Check available disk space (require at least 2GB free)
AVAILABLE_SPACE=$(df -BG "${BACKUP_DEST}" | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "${AVAILABLE_SPACE}" -lt 2 ]; then
    log "ERROR: Insufficient disk space. Available: ${AVAILABLE_SPACE}GB, Required: 2GB"
    exit 1
fi

####################################
# Perform Backup
####################################

log "Backing up ${BACKUP_SOURCE} to ${BACKUP_DEST}/${BACKUP_NAME}"

# Create compressed archive
if sudo tar -czf "${BACKUP_DEST}/${BACKUP_NAME}" \
    -C / \
    --exclude='srv/prometheus/data/wal' \
    srv/ 2>&1 | tee -a "${LOG_FILE}"; then
    
    BACKUP_SIZE=$(du -h "${BACKUP_DEST}/${BACKUP_NAME}" | cut -f1)
    log "SUCCESS: Backup completed - Size: ${BACKUP_SIZE}"
else
    log "ERROR: Backup failed"
    exit 1
fi

####################################
# Verify Backup Integrity
####################################

log "Verifying backup integrity..."

if sudo tar -tzf "${BACKUP_DEST}/${BACKUP_NAME}" > /dev/null 2>&1; then
    log "SUCCESS: Backup integrity verified"
else
    log "ERROR: Backup verification failed"
    exit 1
fi

####################################
# Cleanup Old Backups
####################################

log "Cleaning up backups older than ${BACKUP_RETENTION_DAYS} days..."

DELETED_COUNT=$(find "${BACKUP_DEST}" -name "homelab-backup-*.tar.gz" -mtime +${BACKUP_RETENTION_DAYS} -delete -print | wc -l)

if [ "${DELETED_COUNT}" -gt 0 ]; then
    log "Deleted ${DELETED_COUNT} old backup(s)"
else
    log "No old backups to delete"
fi

####################################
# Summary
####################################

TOTAL_BACKUPS=$(find "${BACKUP_DEST}" -name "homelab-backup-*.tar.gz" | wc -l)
TOTAL_SIZE=$(du -sh "${BACKUP_DEST}" | cut -f1)

log "Backup summary:"
log "  - Total backups: ${TOTAL_BACKUPS}"
log "  - Total size: ${TOTAL_SIZE}"
log "  - Latest backup: ${BACKUP_NAME}"
log "=== Homelab Backup Completed ==="

exit 0