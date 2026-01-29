#!/bin/bash

####################################
# Gateway Node - Firewalld Configuration
####################################

set -euo pipefail

echo "Configuring firewalld for Gateway node..."

# Ensure firewalld is running
sudo systemctl enable --now firewalld

# Set default zones
sudo firewall-cmd --set-default-zone=external

# External zone (WAN-facing interface)
# Allow SSH, HTTP, HTTPS
sudo firewall-cmd --zone=external --permanent --add-service=ssh
sudo firewall-cmd --zone=external --permanent --add-service=http
sudo firewall-cmd --zone=external --permanent --add-service=https

# Internal zone (LAN-facing)
# Allow Prometheus scraping
sudo firewall-cmd --zone=internal --permanent --add-port=9100/tcp

# Add LAN interface to internal zone
# Replace 'eth1' with your actual LAN interface name
# Check with: ip addr
LAN_INTERFACE="eth0"  # UPDATE THIS
sudo firewall-cmd --zone=internal --permanent --add-interface=${LAN_INTERFACE}

# Trust localhost
sudo firewall-cmd --zone=trusted --permanent --add-interface=lo

# Enable masquerading (if Gateway is also routing)
# Uncomment if this node routes traffic between WAN and LAN
# sudo firewall-cmd --zone=external --permanent --add-masquerade

# Reload firewall
sudo firewall-cmd --reload

# Verify configuration
echo ""
echo "Firewall configuration applied. Current status:"
sudo firewall-cmd --list-all-zones

echo ""
echo "Gateway firewalld configuration complete."