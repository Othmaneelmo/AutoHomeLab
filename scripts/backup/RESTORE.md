# Homelab Backup Restore Procedures

## Quick Restore

### Restore Everything
```bash
# List available backups
ls -lh /backups/homelab/

# Extract backup (replace with actual filename)
sudo tar -xzf /backups/homelab/homelab-backup-YYYYMMDD_HHMMSS.tar.gz -C /

# Restart all services
cd ~/homelab
podman-compose -f containers/monitoring/grafana/docker-compose.yml restart
podman-compose -f containers/monitoring/prometheus/docker-compose.yml restart
podman-compose -f containers/apps/vaultwarden/docker-compose.yml restart
```

---

## Selective Restore

### Restore Only Vaultwarden (Password Vault)
```bash
# Stop Vaultwarden
cd ~/homelab/containers/apps/vaultwarden
podman-compose down

# Restore data
sudo tar -xzf /backups/homelab/homelab-backup-YYYYMMDD_HHMMSS.tar.gz \
  -C / \
  srv/vaultwarden/

# Fix permissions
sudo chown -R $USER:$USER /srv/vaultwarden

# Restart Vaultwarden
podman-compose up -d
```

---

### Restore Only Grafana Dashboards
```bash
# Stop Grafana
cd ~/homelab/containers/monitoring/grafana
podman-compose down

# Restore data
sudo tar -xzf /backups/homelab/homelab-backup-YYYYMMDD_HHMMSS.tar.gz \
  -C / \
  srv/grafana/

# Fix permissions
sudo chown -R $USER:$USER /srv/grafana

# Restart Grafana
podman-compose up -d
```

---

### Restore Only Prometheus Metrics
```bash
# Stop Prometheus
cd ~/homelab/containers/monitoring/prometheus
podman-compose down

# Restore data
sudo tar -xzf /backups/homelab/homelab-backup-YYYYMMDD_HHMMSS.tar.gz \
  -C / \
  srv/prometheus/

# Fix permissions
sudo chown -R $USER:$USER /srv/prometheus

# Restart Prometheus
podman-compose up -d
```

---

## Disaster Recovery (Complete System Rebuild)

### Scenario: Host died, rebuilding from scratch

1. **Install fresh OS** (Ubuntu 22.04+)

2. **Install prerequisites:**
```bash
   sudo apt update
   sudo apt install -y podman podman-compose git
```

3. **Clone homelab repository:**
```bash
   git clone <your-repo-url>
   cd homelab
```

4. **Restore backup to a temporary location:**
```bash
   mkdir -p ~/restore-temp
   sudo tar -xzf /path/to/backup.tar.gz -C ~/restore-temp
```

5. **Move data to correct location:**
```bash
   sudo mv ~/restore-temp/srv /srv
   sudo chown -R $USER:$USER /srv
```

6. **Configure environment files:**
```bash
   # Copy examples
   cp containers/monitoring/grafana/.env.example containers/monitoring/grafana/.env
   cp containers/apps/vaultwarden/.env.example containers/apps/vaultwarden/.env
   
   # Edit with your actual values
   nano containers/monitoring/grafana/.env
   nano containers/apps/vaultwarden/.env
```

7. **Start all services:**
```bash
   # Start in order
   cd containers/monitoring/node-exporter && podman-compose up -d
   cd ../prometheus && podman-compose up -d
   cd ../grafana && podman-compose up -d
   cd ../../apps/vaultwarden && podman-compose up -d
   cd ../../reverse-proxy/nginx && podman-compose up -d
```

8. **Obtain SSL certificates** (if DNS is already pointed):
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

9. **Reload Nginx:**
```bash
   podman exec nginx nginx -s reload
```

---

## Verification After Restore
```bash
# Check all services are running
podman ps

# Test endpoints
curl http://localhost:3000/api/health      # Grafana
curl http://localhost:9090/-/healthy       # Prometheus
curl http://localhost:8080/alive           # Vaultwarden

# Check logs for errors
podman logs grafana
podman logs prometheus
podman logs vaultwarden
```

---

## Backup Testing Schedule

**Test restores regularly** to ensure backups are valid:

- **Monthly**: Restore one service (rotate which one)
- **Quarterly**: Full disaster recovery drill
- **After major changes**: Test backup immediately

**Document each test:**
```bash
# Example test log
echo "$(date): Tested Vaultwarden restore - SUCCESS" >> ~/homelab/scripts/backup/test-log.txt
```

---

## Troubleshooting

### Backup failed with "No space left on device"
- Check available space: `df -h /backups`
- Reduce retention: Edit `backup-homelab.sh`, set `BACKUP_RETENTION_DAYS=3`
- Clear old backups manually: `sudo rm /backups/homelab/homelab-backup-OLD*.tar.gz`

### Restore failed with permission errors
```bash
# Fix ownership after restore
sudo chown -R $USER:$USER /srv
```

### Service won't start after restore
```bash
# Check logs
podman logs <container-name>

# Verify data directory exists
ls -la /srv/<service-name>/data

# Restart service
cd containers/<path-to-service>
podman-compose restart
```

---

## Best Practices

1. **Test restores regularly** — untested backups are worthless
2. **Keep backups off-host** — copy to external drive or cloud storage
3. **Monitor backup logs** — check `/var/log/homelab-backup.log` weekly
4. **Document changes** — update this file when adding new services
5. **Automate verification** — consider checksums for critical data