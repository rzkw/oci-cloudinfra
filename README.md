# oci-cloudinfra

Walkable LLC's internal dev environment on Oracle Cloud Infrastructure.

## Deployed Infrastructure

| Resource | Shape / CIDR | Notes |
|----------|-------------|-------|
| VCN | `172.16.0.0/20` | Melbourne region |
| Dev Subnet | `172.16.0.0/24` | Private — no public IPs |
| Internet Gateway | — | Outbound internet |
| Service Gateway | — | Private access to OCI Object Storage |
| Compute Instance | A1.Flex — 4 OCPU, 24 GB RAM | Ubuntu, cloud-init bootstraps Ansible |
| Bastion | Standard | Managed SSH sessions, 3h TTL |
| Budget Alert | $1/month | Email notifications at 1% threshold |

## Repo Layout

| Path | Description |
|------|-------------|
| `terraform/` | Infrastructure modules — VCN, instances, budget |
| `docs/` | Setup guide, IAM details, architecture |
| `scripts/` | Legacy setup script (superseded by Terraform) |
| `plans/` | Implementation plans |

## Remote State

State is stored in OCI Object Storage — `tfstate` bucket in namespace `axvczntoncvg`. Each Terraform module has its own state file.

## Quick Start

```bash
terraform -chdir=terraform/vcn init && terraform -chdir=terraform/vcn apply
terraform -chdir=terraform/instances init && terraform -chdir=terraform/instances apply
terraform -chdir=terraform/budget init && terraform -chdir=terraform/budget apply
```

No `.tfvars` committed. Set variables via environment or CLI flags. See [docs/getting-started.md](docs/getting-started.md) for full setup.

## Documentation

- [Getting Started](docs/getting-started.md) — setup walkthrough and access guide
- [Access Control](docs/access-control.md) — identity domains, policies, agent access
- [Archived Setup Guide](docs/setup-guide-archived.md) — legacy manual OCI console steps (superseded by Terraform)
