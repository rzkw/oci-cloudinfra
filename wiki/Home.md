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
