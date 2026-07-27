# Walkable LLC — OCI Dev Environment

Internal dev machine running on Oracle Cloud. Consists of compute instance within private subnet in VCN,  access via bastion or Tailscale. Serves as Terraform/Ansible control node and image build machine.

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

See [Getting Started](getting-started.md) for the full walkthrough.

## IAM

Two identities in use:

- **Admin user** (in identity domain 'domain-dev') — day-to-day console and API access. Has full control over the operational compartment. MFA enabled, FIDO2 secured.
- **Agent identity** — read-only access for automation workflows (CI, Ansible, agentic exploration). Can inspect resources but can't modify them.
- **Root user** — emergency and billing only. MFA enabled, FIDO2 secured. Never used for daily work.

Cross-domain policies connect the identity domain to the compartment. See [Access Control](access-control.md) for the full policy breakdown.

## Navigation

- [Getting Started](getting-started.md) — setup walkthrough and access guide
- [Access Control](access-control.md) — identity domains, policies, agent access
- [Archived Setup Guide](setup-guide-archived.md) — legacy manual OCI console steps (superseded by Terraform)

## Notes

- State is stored in OCI Object Storage (`tfstate` bucket).
- `scripts/oci-subnet-setup.sh` is a legacy script that predates the Terraform config. Superseded — kept for reference only.
- Provider version drift exists between modules (see AGENTS.md). Being unified.
- SSH access restricted to single IP. Tailscale UDP 41641 also restricted to single IP.

---

Last updated: July 2026
