#!/bin/bash

####################################
# Gateway Node - Fail2Ban Configuration
####################################

set -euo pipefail

echo "Installing and configuring Fail2Ban..."

# Install fail2ban
sudo apt update
sudo apt install -y fail2ban

# Create jail.local configuration
sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[DEFAULT]
# Ban duration (24 hours)
bantime = 86400

# Time window for failures (10 minutes)
findtime = 600

# Max failures before ban
maxretry = 5

# Destination email for notifications
destemail = your-email@example.com
sender = fail2ban@homelab.com

# Action: ban and send email
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 5
bantime = 86400

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 3600

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
bantime = 3600

[nginx-botsearch]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 86400
EOF

# Create nginx-limit-req filter if it doesn't exist
sudo tee /etc/fail2ban/filter.d/nginx-limit-req.conf > /dev/null <<'EOF'
[Definition]
failregex = limiting requests, excess:.* by zone.*client: <HOST>
ignoreregex =
EOF

# Enable and start fail2ban
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# Verify status
sudo fail2ban-client status

echo ""
echo "Fail2Ban configuration complete."
echo "Check banned IPs with: sudo fail2ban-client status sshd"