# Homelab Infrastructure — Personal Project

This homelab started as something I built for myself: I wanted reliable access to my services, better visibility into my systems, and a setup I could confidently maintain and extend. Over time, it turned into a **production-style environment** that I now use to practice real-world infrastructure patterns (containerization, monitoring, security, and automation).

The entire stack is automated so I can tear it down and redeploy it quickly, which lets me experiment safely and iterate without fear of breaking things permanently.

---

## What This Project Demonstrates

* Designing and operating a **containerized Linux environment**
* Making deliberate **security tradeoffs** (rootless containers, HTTPS-only, secrets management)
* Setting up **monitoring and observability** the way it’s done in production
* Writing **maintainable infrastructure**, not one-off scripts
* Treating a “homelab” like a real system people depend on

---

## High-Level Architecture

The lab runs on a Linux host using **Podman (rootless)** instead of Docker. I chose Podman to better understand daemonless container models and reduce the system’s attack surface.

Key design goals:

* **Security first**: no hardcoded secrets, minimal privileges, TLS everywhere
* **Maintainability**: environment-based configuration, clear directory layout
* **Observability**: metrics, dashboards, and uptime checks from day one
* **Extensibility**: adding a new service should be boring and predictable

---

## Services I Run

### Applications

**Jellyfin** : self-hosted media server

* Hardware-accelerated transcoding
* Multiple user profiles and parental controls
* Accessible from mobile, TV, and web clients

**Vaultwarden** : password manager (Bitwarden-compatible)

* WebAuthn / U2F support
* Admin controls and restricted signups
* Fully self-hosted, no third-party dependency

---

### Monitoring & Visibility

**Prometheus**

* Collects host and service-level metrics

**Grafana**

* Dashboards for system health, resource usage, and service behavior

**Node Exporter**

* Low-level host metrics (CPU, memory, disk, network)

**Uptime Kuma**

* External-style monitoring with alerting
* Optional public status page

I built monitoring early because I wanted to **know when something breaks instead of guessing why it feels slow**.

---

### Infrastructure Components

**Nginx reverse proxy**

* Central entry point for all services
* Automatic HTTPS via Let’s Encrypt

**Certbot**

* Handles certificate issuance and renewal
* No certificates or private keys committed to Git

All services are only exposed through the reverse proxy, nothing listens directly on the host.

---

## Repository Layout (Intentional, Not Accidental)

```
homelab/
├── containers/        # All containerized services
│   ├── apps/
│   ├── monitoring/
│   └── reverse-proxy/
├── scripts/           # Automation and backups
├── env/               # Global config templates
├── setup-guide/       # Step-by-step deployment docs
└── README.md
```

Each service is isolated, documented, and configurable through environment files. I structured this the same way I’d expect to see in a small production repo, not a pile of YAML files.

---

## Deployment & Automation

* One-time host preparation (directories, permissions)
* Environment variables control all secrets and config
* Services started in dependency order
* SSL certificates obtained and renewed automatically
* Backups run daily via systemd timers

I can fully redeploy the lab on a fresh machine with minimal manual work.

---

## Backup Strategy

I didn’t treat backups as optional.

* Daily automated backups
* Rotation with retention limits
* Integrity checks after each run
* Documented restore procedures (including partial restores)

This was mainly to force myself to think through **“what would I actually do if this machine died?”**

---

## Security Choices (and Why)

* **Rootless containers** to reduce blast radius
* **No plaintext secrets in Git**
* **HTTPS-only access** for all services
* **Restricted admin panels and signups**

---

## Why I Built This

I learn best by running real systems and living with the consequences. This homelab is where I experiment, break things, fix them, and gradually raise the bar on how “production-like” my setups are.

It’s also become a concrete way to demonstrate skills that are hard to show on a résumé alone: infrastructure design, operational thinking, and long-term maintainability.

