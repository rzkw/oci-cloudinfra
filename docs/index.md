# Walkable LLC — OCI Dev Environment

Internal dev machine running on Oracle Cloud. Consists of compute instance within private subnet in VCN, accessed via Tailscale. Serves as Terraform/Ansible control node and image build machine.

## What's Running

| Resource | Shape / CIDR | Notes |
|----------|-------------|-------|
| VCN | `172.16.0.0/20` | "My internal VCN", Melbourne region |
| Dev Subnet | `172.16.0.0/24` | Internet-gateway route; instance uses its reserved public IP |
| Internet Gateway | — | Outbound internet for the VCN |
| Compute Instance | A1.Flex — 4 OCPU, 24 GB RAM | Ubuntu, cloud-init bootstraps Ansible; accessed via Tailscale |
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
- **Agent identity** — inspect-only access for agentic exploration. Can inspect resources but can't modify them.
- **Root user** — emergency and billing only. MFA enabled, FIDO2 secured. Never used for daily work.

Cross-domain policies connect the identity domain to the compartment. See [Access Control](access-control.md) for the full policy breakdown.

## Navigation

- [Getting Started](getting-started.md) — setup walkthrough and access guide
- [Access Control](access-control.md) — identity domains, policies, agent access
- [Archived Setup Guide](setup-guide-archived.md) — legacy manual OCI console steps (superseded by Terraform)

## Notes

- State is stored in OCI Object Storage (`tfstate` bucket). Each module uses a distinct key — `terraform/<module>/terraform.tfstate` (see `README.md`). A missing backend key defaults to `terraform.tfstate` and collides with other modules.
- Primary access is through Tailscale. OCI Bastion is the backup SSH path; TCP/22 is allowed only from the dev subnet, not from the public internet.
- `scripts/oci-subnet-setup.sh` is a legacy script that predates the Terraform config. Superseded — kept for reference only.
- Provider version drift exists between modules (see AGENTS.md). Being unified.
- UDP/41641 is stateless and open for direct Tailscale connectivity; the home laptop's dynamic IP is handled by Tailscale.

---

Last updated: July 2026
