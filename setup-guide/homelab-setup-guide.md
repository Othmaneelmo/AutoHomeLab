

# Homelab Automation Roadmap — Step by Step

## What I’m Trying to Achieve

I am building a **containerized home lab for monitoring and service automation**:

* **Monitor host and container metrics** (Node Exporter, Prometheus)
* **Visualize metrics** (Grafana)
* **Route traffic securely** (Nginx reverse proxy)
* **Use containers without hardcoding secrets or IPs** (environment variables, `.env` files)
* **Keep everything production-grade** (volumes for persistence, health checks, explicit configuration)

---

## Preconditions (STEP 0)
Make sure I have:

* Linux host (mediaserver)
* Podman installed (`podman` + `podman-compose`) — safer than Docker, rootless [More info](#why-use-podman)

* Non-root user with sudo privileges
* Basic familiarity with Bash, YAML, and systemd


If I don’t, stop and prepare the environment first.

---

## STEP 1 — Create Directory Layout

Create a clean, **personalized folder structure**:

```bash
mkdir -p homelab/containers/monitoring/grafana
mkdir -p homelab/containers/monitoring/prometheus
mkdir -p homelab/containers/monitoring/node-exporter
mkdir -p homelab/containers/reverse-proxy/nginx
```

I should now have:

```
homelab/
└── containers/
    ├── monitoring/
    │   ├── grafana/
    │   ├── prometheus/
    │   └── node-exporter/
    └── reverse-proxy/
        └── nginx/
```

---

## STEP 2 — Create `.env` Files

**Why:** Avoid hardcoding values in YAML. Makes future changes easy and safe for Git.

### Example for Grafana

`homelab/containers/monitoring/grafana/.env`:

```bash
# Service identity
SERVICE_NAME=grafana

# Networking
GRAFANA_PORT=3000

# Storage
GRAFANA_DATA_DIR=/srv/grafana/data

# Security (initial only)
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin
```

Do similar `.env` files for Prometheus and Node Exporter:

* `PROMETHEUS_PORT=9090`
* `PROMETHEUS_DATA_DIR=/srv/prometheus/data`
* `NODE_EXPORTER_PORT=9100`

---

## STEP 3 — Prepare Persistent Storage

```bash
sudo mkdir -p /srv/grafana/data
sudo mkdir -p /srv/prometheus/data
sudo chown -R $USER:$USER /srv/grafana /srv/prometheus
```

**Why:** Containers should not write to `/var/lib` directly. Explicit ownership avoids SELinux & permission issues.

---

## STEP 4 — Create Docker-Compose Files

### Grafana — `docker-compose.yml`

```yaml
version: "3.9"

services:
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped

    ports:
      - "${GRAFANA_PORT}:3000"

    environment:
      GF_SECURITY_ADMIN_USER: "${GRAFANA_ADMIN_USER}"
      GF_SECURITY_ADMIN_PASSWORD: "${GRAFANA_ADMIN_PASSWORD}"

    volumes:
      - "${GRAFANA_DATA_DIR}:/var/lib/grafana"

    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 5s
      retries: 3

volumes:
  grafana-data:
```

**Explanation:**

* **services.grafana.image** → official upstream image
* **ports** → host ↔ container mapping
* **environment** → bootstrap Grafana admin
* **volumes** → persistent data
* **healthcheck** → allows Podman/systemd to monitor container health

---

### Node Exporter — `docker-compose.yml`

```yaml
version: "3.9"

services:
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped

    ports:
      - "${NODE_EXPORTER_PORT}:9100"

    pid: host

    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro

    command:
      - "--path.procfs=/host/proc"
      - "--path.sysfs=/host/sys"
      - "--path.rootfs=/rootfs"
```

**Why:**

* `pid: host` → container sees host processes
* `volumes` → read-only access to host metrics
* `command` → tells Node Exporter where metrics live

---

### Prometheus — `docker-compose.yml`

```yaml
version: "3.9"

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped

    ports:
      - "${PROMETHEUS_PORT}:9090"

    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - "${PROMETHEUS_DATA_DIR}:/prometheus"

    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
```

`prometheus.yml`:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "node"
    static_configs:
      - targets:
          - "localhost:9100"
```

**Explanation:**

* Prometheus scrapes metrics from Node Exporter
* Prometheus config is **explicit**, no auto-generation
* This shows **understanding of what exists** → strong interview answer

---

## STEP 5 — Start Services

```bash
cd homelab/containers/monitoring/grafana
podman-compose up -d

cd ../node-exporter
podman-compose up -d

cd ../prometheus
podman-compose up -d
```

**Test endpoints:**

```bash
curl http://localhost:3000/api/health   # Grafana
curl http://localhost:9100/metrics | head  # Node Exporter
curl http://localhost:9090/-/healthy   # Prometheus
```

Expected:

* Grafana returns `{"database":"ok","message":"ok"}`
* Node Exporter returns text metrics
* Prometheus returns `200 OK`

---

## STEP 6 — Connect Grafana → Prometheus

1. Open Grafana in browser: `http://<server-ip>:3000`
2. Settings → Data Sources → Add Prometheus
3. URL: `http://host.containers.internal:9090`
4. Save & Test
5. Import **Node Exporter dashboard**

---

## STEP 7 — Set Up Reverse Proxy (Nginx)

1. Create directories:

```bash
mkdir -p homelab/containers/reverse-proxy/nginx
cd homelab/containers/reverse-proxy/nginx
```

2. Create `.env`:

```bash
NGINX_HTTP_PORT=80
```

3. Create `nginx.conf`:

```nginx
events {}

http {
    server {
        listen 80;
        server_name _;

        # Grafana
        location /grafana/ {
            proxy_pass http://host.containers.internal:3000/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Prometheus
        location /prometheus/ {
            proxy_pass http://host.containers.internal:9090/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

4. Create `docker-compose.yml`:

```yaml
version: "3.9"

services:
  nginx:
    image: nginx:stable
    container_name: reverse-proxy
    restart: unless-stopped

    ports:
      - "${NGINX_HTTP_PORT}:80"

    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
```

5. Start Nginx:

```bash
podman-compose up -d
```

6. Test:

* `http://<server-ip>/grafana/` → Grafana
* `http://<server-ip>/prometheus/` → Prometheus


---

## STEP 8 — Current File Structure

```
homelab/
├── containers/
│   ├── monitoring/
│   │   ├── grafana/
│   │   │   ├── docker-compose.yml
│   │   │   └── .env
│   │   ├── prometheus/
│   │   │   ├── docker-compose.yml
│   │   │   ├── prometheus.yml
│   │   │   └── .env
│   │   └── node-exporter/
│   │       ├── docker-compose.yml
│   │       └── .env
│   │
│   └── reverse-proxy/
│       └── nginx/
│           ├── docker-compose.yml
│           ├── nginx.conf
│           └── .env
│
├── env/
│   └── example.env
├── scripts/
│   └── bootstrap/
│       └── README.md
├── .gitignore
└── README.md
```

---

At this stage, I have a **fully working, containerized monitoring stack with reverse proxy**


### Why use Podman
Podman is daemonless and rootless, meaning containers can run securely without requiring a constantly running root-owned service. This reduces the attack surface and integrates more cleanly with systemd on Linux. Podman’s CLI is largely Docker-compatible, so existing Docker workflows translate directly, but with better security and tighter system integration. For a personal homelab, this ensures services run safely while giving full control over permissions and isolation.
