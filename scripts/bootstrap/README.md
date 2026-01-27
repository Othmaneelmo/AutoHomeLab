# Bootstrap

This directory is reserved for **host-level bootstrap and hardening scripts**.

The purpose of bootstrap is to prepare a **fresh Linux host** so that it is ready
to reliably run containerized services defined elsewhere in this repository.

> Bootstrap scripts are **not application deployment**.
> They establish a secure, predictable foundation.

---

## Scope

Bootstrap scripts may handle:

- Base system updates
- Required system packages (e.g. podman, firewalld, tooling)
- User and group creation
- Timezone and locale configuration
- Basic security hardening (SSH, firewall defaults)
- SELinux adjustments (if required)
- System-wide directories used by containers (e.g. `/srv/*`)

They **must not**:
- Deploy containers
- Start application services
- Contain application-specific configuration
- Hardcode hostnames, IPs, or domains

---

## Design Principles

### 1. One-Time or Idempotent
Bootstrap scripts should either:
- Be safe to run multiple times (idempotent), **or**
- Clearly document that they are intended to run once on a fresh install

### 2. Host-Role Aware
Scripts should be written so they can support **different host roles**, such as:
- `mediaserver`
- `nasserver`

Role-specific behavior should be controlled via variables or flags, not copied scripts.

### 3. Explicit Over Implicit
Every change made to the system should be:
- Visible
- Documented
- Justifiable

Avoid “magic” behavior.

---

## Relationship to Other Directories

- `containers/`  
  Holds **runtime services** (Grafana, Prometheus, reverse proxy, etc.)

- `env/`  
  Documents required variables and defaults

- `bootstrap/`  
  Prepares the operating system so containers can run cleanly

Bootstrap is intentionally separated so that:
- You can rebuild hosts without redeploying applications
- You can later replace bootstrap with Ansible or another tool

---

## Planned Scripts (Future)

These are **planned**, not yet implemented:

- `00-base.sh`  
  System update, essential packages, basic tooling

- `01-users.sh`  
  Non-root admin user, sudo configuration

- `02-security.sh`  
  SSH hardening, firewall defaults

- `03-storage.sh`  
  Create and permission `/srv/*` directories

Scripts will be added **only when needed**, not preemptively.

---

## Why This Exists

This directory exists to demonstrate:
- Understanding of the difference between host configuration and application deployment
- Intentional infrastructure design
- A clean migration path to configuration management tools (e.g. Ansible)

This is not a collection of random scripts.
It is a boundary.
