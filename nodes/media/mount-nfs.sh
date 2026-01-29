#!/bin/bash

####################################
# Media Node - Mount NFS Shares
####################################

set -euo pipefail

NAS_IP="192.168.1.30"
MOUNT_BASE="/mnt/nas"

echo "Mounting NFS shares from NAS (${NAS_IP})..."

# Install NFS client if needed
if ! command -v mount.nfs &> /dev/null; then
    echo "Installing NFS client..."
    sudo apt update
    sudo apt install -y nfs-common
fi

# Create mount points
sudo mkdir -p ${MOUNT_BASE}/{media,config}

# Mount media share (read-only)
if ! mountpoint -q ${MOUNT_BASE}/media; then
    echo "Mounting ${NAS_IP}:/export/media to ${MOUNT_BASE}/media (read-only)..."
    sudo mount -t nfs -o ro,vers=4 ${NAS_IP}:/export/media ${MOUNT_BASE}/media
else
    echo "${MOUNT_BASE}/media already mounted"
fi

# Mount config share (read-write)
if ! mountpoint -q ${MOUNT_BASE}/config; then
    echo "Mounting ${NAS_IP}:/export/config to ${MOUNT_BASE}/config (read-write)..."
    sudo mount -t nfs -o rw,vers=4 ${NAS_IP}:/export/config ${MOUNT_BASE}/config
else
    echo "${MOUNT_BASE}/config already mounted"
fi

# Add to /etc/fstab for persistence
if ! grep -q "${NAS_IP}:/export/media" /etc/fstab; then
    echo "Adding NFS mounts to /etc/fstab..."
    echo "${NAS_IP}:/export/media ${MOUNT_BASE}/media nfs ro,vers=4,_netdev 0 0" | sudo tee -a /etc/fstab
    echo "${NAS_IP}:/export/config ${MOUNT_BASE}/config nfs rw,vers=4,_netdev 0 0" | sudo tee -a /etc/fstab
fi

# Verify mounts
echo ""
echo "Current NFS mounts:"
df -h | grep ${MOUNT_BASE}

echo ""
echo "NFS mounts configured successfully."