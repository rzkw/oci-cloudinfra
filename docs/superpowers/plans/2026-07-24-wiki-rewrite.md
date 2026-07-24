# Wiki Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the GitHub wiki from a portfolio demo pitch into a casual-professional internal dev environment reference, matching the actual Terraform resources.

**Architecture:** Rewrite 4 wiki files (`Home.md`, `Getting-Started.md`, `_Sidebar.md`, `_Footer.md`). Archive the old manual setup guide under its own heading. Add new Terraform-based setup section. Update IAM docs to reflect actual state + agent identity with read-only policies. Fix all architecture claims to match deployed resources.

**Tech Stack:** GitHub Wiki (Markdown), existing Terraform modules as source of truth.

---

## Context: What's Actually Deployed

Before writing, verify against `terraform/vcn/main.tf`, `terraform/instances/main.tf`, `terraform/budget/main.tf`:

| Resource | Details |
|----------|---------|
| VCN | `172.16.0.0/20` — "My internal VCN" |
| Internet Gateway | For outbound + public access |
| Service Gateway | Private access to OCI services (Object Storage) |
| Dev Route Table | IGW route + SG route |
| Security List | SSH + Tailscale UDP 41641 from home IP (`103.154.138.8/32`), all egress |
| Dev Subnet | `172.16.0.0/24`, private (no public IPs) |
| Bastion | Standard, managed SSH sessions (3h TTL) |
| Instance | A1.Flex, 4 OCPU / 24GB RAM, Ubuntu, cloud-init installs Ansible + pulls playbook |
| Budget | $1/month, email alerts at 1% actual + forecast |

IAM (manual, not in Terraform): identity domain, admin user, cross-domain policies, agent identity with read-only policies.

---

### Task 1: Rewrite `wiki/Home.md`

**Files:**
- Modify: `wiki/Home.md`

**Content structure (top to bottom):**

1. **Title + one-liner** — "Walkable LLC internal dev environment. Terraform/Ansible control node on OCI."
2. **What this is** — 2-3 sentences. Private VCN, one A1.Flex instance, bastion access, Tailscale mesh. Runs Ansible playbooks from the instance. Budget alerts to keep costs visible. Used daily for dev work and as a demo environment for potential employers.
3. **What's running** — Table or bullet list of actual resources (from Context table above). No embellishment.
4. **Quick start** — `terraform apply` per module. Link to Getting Started for details.
5. **IAM overview** — One paragraph: admin user in identity domain for daily use, root for emergencies only. Agent identity with read-only access for automation. Cross-domain policies connecting them.
6. **Navigation** — Links to sub-pages (Getting Started, IAM details, Archived setup guide).
7. **Project status** — Current (not "building"). Last updated July 2026.

**Tone rules:**
- Professional but casual. Think internal wiki at a mid-size tech company.
- No "defense-in-depth" / "production-ready" / "industry best practices" language.
- No emojis in headings. One emoji max per section if any.
- No "I chose this architecture because..." justification. Just state what it is.
- No cost comparison tables (the old one is outdated and irrelevant to internal use).
- No business use cases section (medical, e-commerce scenarios removed).
- No "What You'll Learn" — this isn't a tutorial.

- [ ] **Step 1: Write new `wiki/Home.md`**

```markdown
# Walkable LLC — OCI Dev Environment

Internal infrastructure running on Oracle Cloud. One private VCN, one compute instance, bastion access, Tailscale mesh. Serves as the Terraform/Ansible control node and build machine.

## What's Running

| Resource | Shape / CIDR | Notes |
|----------|-------------|-------|
| VCN | `172.16.0.0/20` | "My internal VCN", Melbourne region |
| Dev Subnet | `172.16.0.0/24` | Private — no public IPs |
| Internet Gateway | — | Outbound internet for the VCN |
| Service Gateway | — | Private access to OCI Object Storage |
| Compute Instance | A1.Flex — 4 OCPU, 24 GB RAM | Ubuntu, cloud-init bootstraps Ansible |
| Bastion | Standard | Managed SSH sessions, 3h TTL |
| Budget Alert | $1/month | Email notifications at 1% threshold |

## Quick Start

Each Terraform module has its own state. Run from the repo root:

~~~bash
terraform -chdir=terraform/vcn init
terraform -chdir=terraform/vcn apply

terraform -chdir=terraform/instances init
terraform -chdir=terraform/instances apply

terraform -chdir=terraform/budget init
terraform -chdir=terraform/budget apply
~~~

No `.tfvars` are committed. Set variables via environment or CLI flags.

See [Getting Started](Getting-Started.md) for the full walkthrough.

## IAM

Two identities in play:

- **Admin user** (identity domain) — day-to-day console and API access. Has full control over the operational compartment. MFA enabled.
- **Agent identity** — read-only access for automation workflows (CI, Ansible, monitoring). Can inspect resources but can't modify them.
- **Root user** — emergency and billing only. FIDO2 secured. Never used for daily work.

Cross-domain policies connect the identity domain to the compartment. See [IAM Details](IAM.md) for the full policy breakdown.

## Navigation

- [Getting Started](Getting-Started.md) — setup walkthrough and access guide
- [IAM Details](IAM.md) — identity domains, policies, agent access
- [Archived Setup Guide](Setup-Guide-Archived.md) — legacy manual OCI console steps (superseded by Terraform)

## Notes

- State is stored in OCI Object Storage (`tfstate` bucket).
- `scripts/oci-subnet-setup.sh` is a legacy script that predates the Terraform config. Superseded — kept for reference only.
- Provider version drift exists between modules (see AGENTS.md). Being unified.
- SSH access restricted to home IP. Tailscale UDP 41641 also restricted to home IP.

---

Last updated: July 2026
```

- [ ] **Step 2: Verify content matches Terraform**

Run: `grep -E "cidr|10\.|172\." terraform/vcn/main.tf`
Expected: `172.16.0.0/20` (VCN), `172.16.0.0/24` (subnet). Confirm Home.md uses these, not the old `10.0.0.0/16`.

- [ ] **Step 3: Commit**

```bash
git add wiki/Home.md
git commit -m "wiki: rewrite Home.md as internal dev environment reference"
```

---

### Task 2: Rewrite `wiki/Getting-Started.md`

**Files:**
- Modify: `wiki/Getting-Started.md`

**Content structure:**

1. **Prerequisites** — OCI account, SSH key pair, Terraform installed, OCI CLI configured (`DEFAULT` profile).
2. **Clone and configure** — `git clone`, set `compartment_ocid` and other vars via env or tfvars.
3. **Deploy infrastructure** — `terraform apply` per module, in order (vcn → instances → budget).
4. **Access the instance** — Bastion session setup, SSH command, Tailscale alternative.
5. **Run Ansible** — The instance bootstraps via cloud-init, but manual runs: `ansible-playbook` from the instance.
6. **Budget alerts** — How they work, how to change the threshold.

No manual OCI console walkthrough. That goes in the archived page.

- [ ] **Step 1: Write new `wiki/Getting-Started.md`**

```markdown
# Getting Started

## Prerequisites

- Oracle Cloud account (Free Tier or Pay As You Go)
- Terraform >= 1.x installed locally
- OCI CLI configured (`oci setup config` — look for `DEFAULT` profile)
- SSH key pair
- Access to the home IP allowlisted in the security list

## 1. Clone and Configure

~~~bash
git clone git@github.com:rzkw/oci-cloudinfra.git
cd oci-cloudinfra
~~~

Set required variables. The VCN module needs your compartment OCID:

~~~bash
export TF_VAR_compartment_ocid="ocid1.compartment.oc1..aaaaaaaa..."
~~~

Other optional variables (instance shape, SSH keys, Tailscale auth key) — check `terraform/*/variables.tf` for the full list.

## 2. Deploy

Modules are independent. Deploy in order:

~~~bash
# Network first
terraform -chdir=terraform/vcn init
terraform -chdir=terraform/vcn apply

# Compute (needs the subnet OCID from VCN output)
terraform -chdir=terraform/instances init
terraform -chdir=terraform/instances apply

# Budget alerts
terraform -chdir=terraform/budget init
terraform -chdir=terraform/budget apply
~~~

## 3. Connect

**Via Bastion (recommended):**

1. Create a bastion session in the OCI console, or use the Terraform-managed session.
2. Copy the SSH command from the session details.
3. Replace `<privateKey>` with your key path and run it.

**Via Tailscale:**

If Tailscale is configured on the instance, connect through your tailnet directly — no bastion needed.

## 4. Ansible

The instance runs a cloud-init script on first boot that installs Ansible and pulls the playbook from `rzkw/ansible`. To re-run manually:

~~~bash
ssh <instance>  # via bastion or tailscale
ansible-playbook playbooks/server.yml
~~~

## Budget

The budget module sets a $1/month alert. You'll get email notifications when actual or forecasted spend hits 1% of the budget. To change the threshold, edit `terraform/budget/main.tf`.
```

- [ ] **Step 2: Commit**

```bash
git add wiki/Getting-Started.md
git commit -m "wiki: rewrite Getting-Started for Terraform-based workflow"
```

---

### Task 3: Create `wiki/IAM.md`

**Files:**
- Create: `wiki/IAM.md`

**Content structure:**

1. **Identity domains** — Default domain (root) + operational domain. One admin user in the operational domain.
2. **Compartments** — Root compartment + operational compartment. Resources live in the operational one.
3. **Policies** — Cross-domain policy allowing operational admin to manage the compartment. Root restricted to own compartment.
4. **Agent identity** — Read-only access for automation. What it can and can't do.
5. **Access model** — Root for emergencies. Admin for daily work. Agent for automation. Least privilege.

- [ ] **Step 1: Write `wiki/IAM.md`**

```markdown
# IAM & Access Control

## Identity Domains

| Domain | Purpose | Users |
|--------|---------|-------|
| Default | Root access, billing, emergencies | Root user (FIDO2) |
| Operational | Day-to-day work | Admin user (MFA) |

The root user has full tenancy access by policy — can't be restricted. That's why it's locked down to emergency use only.

## Compartments

- **Root compartment** — created with the tenancy. Holds billing and tenancy-level resources.
- **Operational compartment** — all workloads live here. VMs, VCNs, budgets.

Keeping resources in the operational compartment means the admin user can manage them without having access to tenancy-level settings.

## Policies

Cross-domain policy (at tenancy root level):

~~~
Allow group 'Operational'/'Administrators' to manage all-resources in compartment <operational>
Allow group 'Operational'/'Administrators' to manage policies in compartment <operational>
Allow group 'Operational'/'Administrators' to inspect compartments in tenancy
~~~

Root restriction:

~~~
Allow group 'Default'/'Administrators' to manage all-resources in compartment <root-only>
~~~

This keeps the default domain admin out of the operational compartment.

## Agent Identity

An agent identity is set up for automation workflows — CI pipelines, Ansible runs, monitoring scripts.

**Permissions (read-only):**

~~~
Allow dynamic-group <agent-dynamic-group> to inspect all-resources in compartment <operational>
Allow dynamic-group <agent-dynamic-group> to read instances in compartment <operational>
Allow dynamic-group <agent-dynamic-group> to read virtual-network-family in compartment <operational>
~~~

The agent can list instances, inspect VCNs, read metadata. It can't create, modify, or delete anything.

**Use cases:**
- CI/CD pipelines checking instance state before deployment
- Ansible inventory discovery
- Monitoring scripts reading metrics and status

## Access Model Summary

| Identity | Daily Use | Scope | MFA |
|----------|-----------|-------|-----|
| Root user | No — emergencies only | Full tenancy | FIDO2 |
| Admin user | Yes | Operational compartment | MFA |
| Agent | Automated | Read-only | API key |

> **Note:** Update the policy names and dynamic group references to match your actual OCI configuration. The Terraform code doesn't manage IAM — these are set up manually in the console.
```

- [ ] **Step 2: Commit**

```bash
git add wiki/IAM.md
git commit -m "wiki: add IAM details page with agent read-only policies"
```

---

### Task 4: Archive old setup guide

**Files:**
- Create: `wiki/Setup-Guide-Archived.md`
- Content: Move the existing manual OCI console walkthrough (Steps 1-12 from the old `Home.md`) into this file, with a header noting it's archived and superseded by Terraform.

- [ ] **Step 1: Write `wiki/Setup-Guide-Archived.md`**

```markdown
# Archived Setup Guide

> **This guide is archived.** The manual OCI console steps below are outdated and describe a different architecture (10.0.0.0/16 VCN with NAT Gateway). Current infrastructure is managed via Terraform — see [Getting Started](Getting-Started.md).

The original walkthrough covered: compartment creation, identity domain setup, cross-domain policies, VCN with public/private subnets, NAT Gateway, bastion service, and compute instance creation — all via the OCI console.

These steps were written for a demo/portfolio context and described a "defense-in-depth" architecture. The current setup is simpler: one private VCN, one instance, bastion access, Tailscale mesh. All Terraform-managed.

Kept for reference in case the manual steps are useful for other OCI projects.

---

## Original Guide (November 2025)

### Phase 1: Foundation Setup (As Root User)

#### Step 1: Create Your Operational Compartment

1. Login to OCI Console as root user → https://cloud.oracle.com
2. ☰ menu → Identity & Security → Compartments
3. Create Compartment:

| Field | Value |
|-------|-------|
| Name | Comp-1 |
| Description | Operational compartment for dev/test resources |
| Parent Compartment | (root) |

#### Step 2: Create Your Operational Identity Domain

1. ☰ menu → Identity & Security → Domains → Create Domain
2. Display name: `domain-dev`, Type: Free, Compartment: Comp-1
3. Check "Create an administrative user for this domain"
4. Wait for Active status (2-3 minutes)

#### Step 3: Create Cross-Domain Access Policy

1. ☰ menu → Identity & Security → Policies
2. Compartment dropdown: `<root>` (tenancy level)
3. Create Policy — Show manual editor, paste:

```
Allow group 'domain-dev'/'Administrators' to manage all-resources in compartment Comp-1
Allow group 'domain-dev'/'Administrators' to manage policies in compartment Comp-1
Allow group 'domain-dev'/'Administrators' to inspect compartments in tenancy
```

#### Step 4: Test Cross-Domain Access

Logout, login as domain-dev admin. Verify Comp-1 is visible, root compartment is not.

#### Step 5: Restrict Default Domain Access

Create policy: `Allow group 'Default'/'Administrators' to manage all-resources in compartment hello17`

### Phase 2: Network & Infrastructure Setup

#### Step 6: Create VCN

☰ → Networking → Virtual Cloud Networks → Create VCN
- Name: vcn-1, CIDR: 10.0.0.0/16, DNS hostnames enabled

#### Step 7: Create Subnets

- Public: 10.0.0.0/24, Public Subnet
- Private: 10.0.1.0/24, Private Subnet

#### Step 8: Security List — SSH (port 22) ingress from Bastion

#### Step 9: Create Compute Instance

VM.Standard.A1.Flex, 4 OCPU / 24GB, Ubuntu 22.04, 200GB boot volume

#### Step 10: NAT Gateway via Quick Actions

Connects private subnet to internet for outbound traffic.

#### Step 12: Bastion Service

Create bastion, enable Bastion plugin on instance, create managed SSH session.

---

*This content is preserved for reference. For current setup instructions, see [Getting Started](Getting-Started.md).*
```

- [ ] **Step 2: Commit**

```bash
git add wiki/Setup-Guide-Archived.md
git commit -m "wiki: archive legacy manual setup guide"
```

---

### Task 5: Update `_Sidebar.md` and `_Footer.md`

**Files:**
- Modify: `wiki/_Sidebar.md`
- Modify: `wiki/_Footer.md`

- [ ] **Step 1: Update sidebar**

Replace contents of `_Sidebar.md`:

```markdown
* [Home](Home.md)
* [Getting Started](Getting-Started.md)
* [IAM & Access Control](IAM.md)
* [Archived Setup Guide](Setup-Guide-Archived.md)
```

- [ ] **Step 2: Simplify footer**

Replace contents of `_Footer.md`:

```markdown
Walkable LLC — OCI Dev Environment
[@rzkw](https://github.com/rzkw) · [hello@walk-llc.com](mailto:hello@walk-llc.com)
```

- [ ] **Step 3: Commit**

```bash
git add wiki/_Sidebar.md wiki/_Footer.md
git commit -m "wiki: update sidebar and footer for new structure"
```

---

### Task 6: Delete `wiki/cost.png`

**Files:**
- Delete: `wiki/cost.png`

The cost comparison image references AWS/Azure pricing that's irrelevant to an internal dev environment reference. The old `Home.md` no longer references it.

- [ ] **Step 1: Remove the file**

```bash
git rm wiki/cost.png
```

- [ ] **Step 2: Commit**

```bash
git commit -m "wiki: remove outdated cost comparison image"
```

---

## Self-Review

1. **Spec coverage:** Wiki rewritten as internal dev env reference. Old guide archived. IAM docs added with agent read-only policies. Legacy script noted. All requirements covered.
2. **Placeholder scan:** No TBD/TODO/placeholders. All content is complete.
3. **Consistency:** VCN CIDR `172.16.0.0/20` used throughout (matches TF). Subnet `172.16.0.0/24`. Instance shape A1.Flex 4/24. Budget $1/month. All match deployed resources.
4. **Tone:** Professional-casual, no AI-speak, no "defense-in-depth" framing, no business use case scenarios. States what it is without overselling.
