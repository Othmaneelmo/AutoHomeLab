# Homelab Infrastructure

A production-grade, containerized home lab for self-hosted services with monitoring, security, and automation.

## Architecture

This homelab uses **Podman** (rootless, daemonless) for container orchestration with a focus on:

- **Security**: No hardcoded secrets, HTTPS-only access, minimal attack surface
- **Maintainability**: Environment-based configuration, explicit file structure
- **Observability**: Full-stack monitoring with Prometheus and Grafana
- **Scalability**: Modular design for easy service addition

---

## Current Services

### Applications
**Vaultwarden** (`vault.example.com`) — Self-hosted password manager
- Bitwarden-compatible API
- WebAuthn/U2F support
- Admin panel for user management
### Monitoring
- **Uptime Kuma** (`status.example.com`) — Service health monitoring and status page
- **Grafana** (`grafana.example.com`) — Metrics visualization and dashboards
- **Prometheus** (`prometheus.example.com`) — Time-series metrics database
- **Node Exporter** — Host system metrics collector
### Infrastructure
- **Nginx** — Reverse proxy with automatic SSL/TLS via Let's Encrypt
- **Certbot** — Automated certificate issuance and renewal

---

## Directory Structure
```
homelab/
├── containers/
│   ├── apps/
│   │   └── vaultwarden/          # Password manager
│   │       ├── docker-compose.yml
│   │       └── .env.example
│   ├── monitoring/
│   │   ├── uptime-kuma/          # Service health monitoring
│   │   │   ├── docker-compose.yml
│   │   │   └── .env.example
│   │   ├── grafana/              # Visualization
│   │   ├── prometheus/           # Metrics database
│   │   └── node-exporter/        # System metrics
│   └── reverse-proxy/
│       └── nginx/                # HTTPS termination
│           ├── docker-compose.yml
│           ├── nginx.conf
│           └── .env.example
├── scripts/
│   └── backup/                   # Automated backups
│       ├── backup-homelab.sh
│       ├── check-backup-status.sh
│       └── RESTORE.md
├── env/
│   └── example.env               # Global configuration template
├── setup-guide/
│   └── homelab-setup-guide.md    # Step-by-step instructions
├── .gitignore
└── README.md
```

---

## Quick Start

### Prerequisites
- Linux host (Ubuntu 22.04+ or similar)
- Podman and podman-compose installed
- Domain names pointed to your server
- Ports 80 and 443 open on your firewall

### Initial Setup

1. **Clone the repository:**
```bash
   git clone <your-repo-url>
   cd homelab
```

2. **Prepare persistent storage:**
```bash
   sudo mkdir -p /srv/{grafana,prometheus,vaultwarden}/data
   sudo chown -R $USER:$USER /srv
```

3. **Configure each service:**
```bash
   # Copy example environment files
   cp containers/monitoring/grafana/.env.example containers/monitoring/grafana/.env
   cp containers/apps/vaultwarden/.env.example containers/apps/vaultwarden/.env
   
   # Edit with your actual values
   nano containers/monitoring/grafana/.env
   nano containers/apps/vaultwarden/.env
```

4. **Start services:**
```bash
   # Monitoring stack
   cd containers/monitoring/node-exporter && podman-compose up -d
   cd ../prometheus && podman-compose up -d
   cd ../grafana && podman-compose up -d
   
   # Applications
   cd ../../apps/vaultwarden && podman-compose up -d
   
   # Reverse proxy (start last)
   cd ../../reverse-proxy/nginx && podman-compose up -d
```

5. **Obtain SSL certificates:**
```bash
   cd containers/reverse-proxy/nginx
   podman-compose run --rm certbot certonly --webroot \
     -w /var/www/certbot \
     -d grafana.example.com \
     -d prometheus.example.com \
     -d vault.example.com \
     --email your-email@example.com \
     --agree-tos
```

6. **Reload Nginx:**
```bash
   podman exec nginx nginx -s reload
```

---

## Configuration



**Global variables** are documented in `env/example.env` for reference.

### SSL/TLS Certificates

- Certificates are automatically managed by Certbot
- Renewal runs every 12 hours via `certbot-renew` container
- Certificates stored in `containers/reverse-proxy/nginx/certbot/conf`
- **Never commit certificates to Git**

---

## Security

- **No hardcoded secrets**: All sensitive data in `.env` files
- **HTTPS-only**: All services behind SSL/TLS termination
- **Rootless containers**: Podman runs without root privileges
- **Admin authentication**: Admin panels protected by tokens
- **Signup restrictions**: Public registration disabled by default

---

## Monitoring


### Grafana Dashboards

Access Grafana at `https://grafana.example.com` and import:

- **Node Exporter Full** (Dashboard ID: 1860) — System metrics
- **Prometheus 2.0 Overview** (Dashboard ID: 3662) — Prometheus health

### Prometheus Targets

Check scrape status at `https://prometheus.example.com/targets`

---
## Health Monitoring

### Uptime Kuma Dashboard

Access the monitoring dashboard at `https://status.example.com`

**Monitored services:**
- Grafana (HTTPS endpoint)
- Prometheus (health endpoint)
- Vaultwarden (alive endpoint)
- Node Exporter (metrics endpoint)
- Nginx (HTTP → HTTPS redirect)

**Features:**
- Real-time status updates via WebSocket
- Historical uptime statistics
- Email notifications on downtime
- Public status page (optional)

### Configure Notifications

1. Login to Uptime Kuma
2. Settings → Notifications
3. Add SMTP, Slack, Discord, or other integrations
4. Apply to individual monitors

### Public Status Page

Share service status with others: `https://status.example.com/status/your-slug`

---
## Backup Strategy

### Automated Backups

**What's backed up:**
- `/srv/grafana/data` — Grafana dashboards and configuration
- `/srv/prometheus/data` — Metrics time-series database
- `/srv/vaultwarden/data` — Password vault database

**Schedule:**
- Runs daily at 2:00 AM via systemd timer
- Retention: 7 days (automatic rotation)
- Location: `/backups/homelab/`

**Verification:**
- Integrity check after each backup
- Manual testing recommended monthly

### Check Backup Status
```bash
# View backup status
~/homelab/scripts/backup/check-backup-status.sh

# View backup logs
sudo journalctl -u homelab-backup.service

# List all backups
ls -lh /backups/homelab/
```

### Manual Backup
```bash
# Run backup immediately
sudo systemctl start homelab-backup.service

# Monitor progress
sudo journalctl -u homelab-backup.service -f
```

### Restore Procedures

See [RESTORE.md](scripts/backup/RESTORE.md) for detailed restore procedures including:
- Full system restore
- Selective service restore
- Disaster recovery guide
## Maintenance

### Update containers
```bash
cd containers/<service-name>
podman-compose pull
podman-compose up -d
```

### View logs
```bash
podman logs -f <container-name>
```

### Restart services
```bash
podman-compose restart
```

---

## Troubleshooting

### Service won't start
```bash
# Check container status
podman ps -a

# View logs
podman logs <container-name>

# Check environment variables
cat .env
```

### Certificate issues
```bash
# Test renewal
podman-compose run --rm certbot renew --dry-run

# Force renewal
podman-compose run --rm certbot renew --force-renewal

# Reload Nginx
podman exec nginx nginx -s reload
```

### Permission errors
```bash
# Fix /srv ownership
sudo chown -R $USER:$USER /srv

# Check SELinux (if enabled)
sudo ausearch -m avc -ts recent
```

---

## Contributing

This is a personal homelab, but contributions are welcome:

1. Fork the repository
2. Create a feature branch
3. Update documentation
4. Test changes thoroughly
5. Submit a pull request



---

## Resources

- [Detailed Setup Guide](setup-guide/homelab-setup-guide.md)
- [Podman Documentation](https://docs.podman.io/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki)

---

## License

MIT License — See LICENSE file for details

---

## Acknowledgments

Built with guidance from the homelab and self-hosting communities.