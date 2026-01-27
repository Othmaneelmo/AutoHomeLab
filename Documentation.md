# Homelab Automation – Design & Implementation Documentation

## 1. Purpose of This Project

This repository documents the step‑by‑step design and implementation of a **personal automation homelab**. The goal is not to copy an existing setup, but to:

* Build infrastructure **from first principles**
* Understand *why* each component exists
* Keep the system explainable, auditable, and extensible
* Maintain credibility for interviews and long‑term maintenance

All decisions favor **clarity, observability, and separation of concerns** over shortcuts.

---

## 2. High‑Level Architecture

The homelab is designed around the following ideas:

* **Containers** are used for application services
* **Podman + podman‑compose** are used instead of Docker (daemonless, rootless‑friendly)
* **Monitoring is foundational**, not an afterthought
* **Ingress is centralized** through a reverse proxy
* Configuration is **explicit**, not auto‑generated

### Current Logical Components

* **Grafana** – Visualization layer
* **Prometheus** – Metrics collection
* **Node Exporter** – Host‑level metrics
* **Nginx** – Reverse proxy / ingress

---

## 3. Repository Structure (Current State)

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
│
├── scripts/
│   └── bootstrap/
│       └── README.md
│
├── README.md
└── documentation.md
```

### Structural Principles

* **One directory = one responsibility**
* Each service is **independently runnable**
* No global, monolithic `docker-compose.yml`
* Clear separation between:

  * Containers
  * Host bootstrapping (future)
  * Documentation

---

## 4. Why Podman + podman‑compose

Instead of Docker:

* Podman is **daemonless** (better security model)
* Compatible with Docker images and compose files
* Rootless operation is possible
* Increasingly used in enterprise Linux environments

Using `podman-compose` preserves familiarity while improving security posture.

---

## 5. Service‑by‑Service Breakdown

### 5.1 Grafana

**Purpose:** Visualization and dashboarding

**Why first?**

* Forces early thinking about observability
* Makes later debugging easier

**Key decisions:**

* Persistent storage mounted from host (`/srv/grafana/data`)
* Admin credentials injected only for initial bootstrap
* Healthcheck enabled to allow external supervision

**Important files:**

* `docker-compose.yml` – Service definition
* `.env` – Port, data path, credentials

Grafana does *not* scrape metrics itself; it depends on Prometheus.

---

### 5.2 Node Exporter

**Purpose:** Export host‑level metrics (CPU, memory, disk, network)

**Why this exists:**

* Containers alone do not expose host health
* Required for meaningful infrastructure monitoring

**Key decisions:**

* Runs as a container but reads host namespaces
* Mounts `/proc`, `/sys`, and `/` as read‑only
* Uses `pid: host` to see real process data

Node Exporter exposes metrics on port `9100`.

---

### 5.3 Prometheus

**Purpose:** Metrics collection and time‑series storage

**Why Prometheus:**

* Industry standard
* Pull‑based model is simple and explicit
* Excellent Grafana integration

**Key decisions:**

* Static scrape configuration (no hidden discovery)
* Explicit targets for transparency
* Persistent TSDB storage on host

Prometheus is the *only* component that scrapes metrics.

---

### 5.4 Nginx Reverse Proxy

**Purpose:** Single ingress point for services

**Why a reverse proxy:**

* Avoid exposing multiple ports
* Clean URLs
* Foundation for TLS and subdomains

**Why Nginx:**

* Minimal
* Well‑understood
* Excellent reverse‑proxy performance

**Current mode:**

* HTTP only
* Path‑based routing (`/grafana/`)

TLS and subdomains are intentionally deferred.

---

## 6. Environment Variables Strategy

Each service directory contains its own `.env` file.

**Reasons:**

* Locality of configuration
* Services can be moved or deleted independently
* Prevents global configuration sprawl

An `env/example.env` file exists only as documentation.

---

## 7. What Is Intentionally NOT Done Yet

These are postponed on purpose:

* TLS certificates
* Public domains
* Secrets management
* Multi‑host orchestration
* Ansible / Terraform
* Media or download services

The goal is **correct sequencing**, not feature rush.

---

## 8. Operational Workflow

Starting a service:

```bash
cd containers/monitoring/grafana
podman-compose up -d
```

Stopping a service:

```bash
podman-compose down
```

Each service is controlled independently.

---

## 9. Design Philosophy Summary

This homelab is built to be:

* **Understandable** – no magic generation
* **Explainable** – every file has a reason
* **Composable** – services can be added safely
* **Interview‑credible** – decisions can be defended

The focus is on *infrastructure thinking*, not just running apps.

---

## 10. Planned Next Steps

Future phases (not yet implemented):

1. TLS via self‑signed → Let’s Encrypt
2. Subdomain‑based routing
3. Non‑monitoring services (media, NAS)
4. Role separation (mediaserver / nasserver)
5. Host bootstrap automation
6. Ansible refactor

Each phase will extend this documentation.

---

