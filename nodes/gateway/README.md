# Gateway Node

**Role:** Ingress/egress control, TLS termination, reverse proxy  
**IP Address:** 192.168.1.10  
**Hostname:** gateway.homelab.local

---

## Services Running

- **Nginx** (reverse proxy, TLS termination)
- **Certbot** (automatic certificate renewal)
- **node-exporter** (Prometheus metrics)
- **firewalld** (host firewall)
- **Fail2Ban** (intrusion prevention)

---

## Deployment

### 1. Configure Environment
```bash
# Update .env with your actual values
nano .env
```

### 2. Configure Firewall
```bash
# Review and update LAN interface name
nano firewalld-config.sh

# Apply firewall rules
./firewalld-config.sh
```

### 3. Configure Fail2Ban
```bash
# Update email address
nano fail2ban-config.sh

# Install and configure
./fail2ban-config.sh
```

### 4. Start Services
```bash
# Start containers
podman-compose up -d

# Verify
podman ps
```

### 5. Obtain SSL Certificates
```bash
# Obtain certificate for each domain
podman-compose run --rm certbot certonly --webroot \
  -w /var/www/certbot \
  -d media.homelab.com \
  --email your-email@example.com \
  --agree-tos

# Repeat for other domains
# - vault.homelab.com
# - status.homelab.com
# - grafana.homelab.com

# Reload Nginx
podman exec gateway-nginx nginx -s reload
```

---

## Maintenance

### Reload Nginx Configuration
```bash
podman exec gateway-nginx nginx -t
podman exec gateway-nginx nginx -s reload
```

### Check Fail2Ban Status
```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

### Unban an IP
```bash
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

### View Nginx Logs
```bash
podman logs gateway-nginx
```

### Test SSL Configuration
```bash
curl -I https://media.homelab.com
```

---

## Firewall Rules

**External zone (WAN):**
- Port 22 (SSH) - with Fail2Ban protection
- Port 80 (HTTP) - redirects to HTTPS
- Port 443 (HTTPS) - reverse proxy

**Internal zone (LAN):**
- Port 9100 (node-exporter) - Prometheus scraping

---

## Monitoring

**Metrics endpoint:** `http://192.168.1.10:9100/metrics`

**Key metrics:**
- Request rate per backend
- Response time distribution
- TLS certificate expiration
- Nginx worker status
- Failed authentication attempts

---

## Troubleshooting

### Nginx won't start
```bash
# Check configuration syntax
podman exec gateway-nginx nginx -t

# Check logs
podman logs gateway-nginx

# Verify certificates exist
ls -la certbot/conf/live/
```

### Can't access services externally
```bash
# Check firewall
sudo firewall-cmd --list-all-zones

# Check port forwarding on router
# Ensure ports 80, 443 forward to 192.168.1.10

# Test from outside network
curl -I http://your-public-ip
```

### Certificate renewal failing
```bash
# Manual renewal test
podman-compose run --rm certbot renew --dry-run

# Check certbot logs
podman logs gateway-certbot
```