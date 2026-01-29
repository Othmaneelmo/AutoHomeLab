#!/bin/bash

####################################
# Media Node - Firewalld Configuration
####################################

set -euo pipefail

echo "Configuring firewalld for Media node..."

# Ensure firewalld is running
sudo systemctl enable --now firewalld

# Set default zone
sudo firewall-cmd --set-default-zone=internal

# Internal zone (allow from Gateway and Monitoring)
# Gateway can access all services
sudo firewall-cmd --zone=internal --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.10"
  port port="8096" protocol="tcp" accept'

sudo firewall-cmd --zone=internal --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.10"
  port port="8080" protocol="tcp" accept'

sudo firewall-cmd --zone=internal --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.10"
  port port="3001" protocol="tcp" accept'

sudo firewall-cmd --zone=internal --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.10"
  port port="3000" protocol="tcp" accept'

# Monitoring can scrape metrics
sudo firewall-cmd --zone=internal --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.40"
  port port="9100" protocol="tcp" accept'

# Allow SSH from internal network
sudo firewall-cmd --zone=internal --permanent --add-service=ssh

# Trust localhost
sudo firewall-cmd --zone=trusted --permanent --add-interface=lo

# Reload firewall
sudo firewall-cmd --reload

# Verify configuration
echo ""
echo "Firewall configuration applied. Current status:"
sudo firewall-cmd --list-all-zones

echo ""
echo "Media node firewalld configuration complete."