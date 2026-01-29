# Media Node

**Role:** Application hosting (user-facing services)  
**IP Address:** 192.168.1.20  
**Hostname:** media.homelab.local

---

## Services Running

- **Jellyfin** (media streaming server)
- **Vaultwarden** (password manager)
- **Uptime Kuma** (service monitoring dashboard)
- **Grafana** (metrics visualization)
- **node-exporter** (Prometheus metrics)
- **firewalld** (host firewall)

---

## Prerequisites

1. **NAS node must be running** with NFS shares exported
2. **Monitoring node** should be configured (for Grafana data source)

---

## Deployment

### 1. Mount NFS Shares
```bash
# Review and update NAS IP if needed
nano mount-nfs.sh

# Mount shares
./mount-nfs.sh

# Verify
df -h | grep /mnt/nas
```

### 2. Configure Environment
```bash
# Update .env with your actual values
nano .env

# Generate secure tokens
openssl rand -base64 48  # Use for VAULTWARDEN_ADMIN_TOKEN
```

### 3. Create Config Directories on NAS

**On NAS node, create these directories:**
```bash
mkdir -p /tank/config/{jellyfin,vaultwarden,grafana,uptime-kuma}
```

### 4. Configure Firewall
```bash
# Apply firewall rules
./firewalld-config.sh
```

### 5. Start Services
```bash
# Start all containers
podman-compose up -d

# Verify
podman ps
```

### 6. Initial Service Configuration

**Jellyfin:**
- Open: `http://192.168.1.20:8096`
- Create admin account
- Add libraries: /media/movies, /media/tv, /media/music
- Configure network: Dashboard → Networking → Proxy mode

**Grafana:**
- Open: `http://192.168.1.20:3000`
- Login with admin credentials from .env
- Add Prometheus data source: `http://192.168.1.40:9090`

**Uptime Kuma:**
- Open: `http://192.168.1.20:3001`
- Create admin account
- Add monitors for all services

**Vaultwarden:**
- Open: `http://192.168.1.20:8080`
- Create account (or use admin panel if signups disabled)

---

## Maintenance

### Restart a Service
```bash
podman-compose restart jellyfin
```

### View Logs
```bash
podman logs -f media-jellyfin
```

### Update Containers
```bash
podman-compose pull
podman-compose up -d
```

### Unmount NFS Shares (for maintenance)
```bash
sudo umount /mnt/nas/media
sudo umount /mnt/nas/config
```

---

## Firewall Rules

**Allowed connections:**
- 192.168.1.10 (Gateway) → ports 8096, 8080, 3001, 3000
- 192.168.1.40 (Monitoring) → port 9100
- 192.168.1.0/24 (LAN) → port 22 (SSH)

---

## Monitoring

**Metrics endpoint:** `http://192.168.1.20:9100/metrics`

**Key metrics:**
- Container resource usage (CPU, memory)
- Service response times
- NFS mount availability
- Application-specific metrics (Jellyfin streams, Grafana queries)

---

## Troubleshooting

### NFS mount fails
```bash
# Check network connectivity to NAS
ping 192.168.1.30

# Check NFS service on NAS
showmount -e 192.168.1.30

# Check firewall
sudo firewall-cmd --list-all
```

### Container won't start
```bash
# Check logs
podman logs media-jellyfin

# Check permissions on NFS mount
ls -la /mnt/nas/config/jellyfin
```

### Can't access from Gateway
```bash
# Check firewall rules
sudo firewall-cmd --list-all

# Test locally
curl http://localhost:8096/health
```