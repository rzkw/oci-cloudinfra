# oci-cloudinfra

Walkable LLC's internal dev environment on Oracle Cloud Infrastructure.

## Deployed Infrastructure

| Resource | Shape / CIDR | Notes |
|----------|-------------|-------|
| VCN | `172.16.0.0/20` | Melbourne region |
| Dev Subnet | `172.16.0.0/24` | Private — no public IPs |
| Internet Gateway | — | Outbound internet |
| Compute Instance | A1.Flex — 4 OCPU, 24 GB RAM | Ubuntu, cloud-init bootstraps Ansible; accessed via Tailscale |
| Budget Alert | $1/month | Email notifications at 1% threshold |

## Cost Comparison — OCI vs AWS

| Resource | AWS equivalent | OCI/mo | AWS/mo | OCI/yr | AWS/yr |
|----------|----------------|--------|--------|--------|--------|
| Bastion (STANDARD, MANAGED_SSH) | EC2 `t4g.nano` jump box | A$0 | US$3 | A$0 | US$36 |
| Compute `VM.Standard.A1.Flex` (4 OCPU / 24 GB) | EC2 `t4g.small` | A$0 | US$12 | A$0 | US$147 |
| NAT Gateway | NAT Gateway | A$0¹ | US$33 | A$0 | US$394 |
| **Total** | | **A$0** | **≈US$48** | **A$0** | **≈US$578** |

¹ Dev traffic stays within the free egress allowance (first 10 TB/month).
AWS figures are us-east-1 on-demand list prices in USD; OCI uses AUD list
pricing — Always Free allowances cover the entire stack.
Sources: [OCI Price List API](https://apexapps.oracle.com/pls/apex/cetools/api/v1/products/),
[AWS EC2 pricing](https://aws.amazon.com/ec2/pricing/on-demand/),
[AWS VPC pricing](https://aws.amazon.com/vpc/pricing/).

## Repo Layout

| Path | Description |
|------|-------------|
| `terraform/` | Infrastructure modules — VCN, instances, budget |
| `docs/` | Setup guide, IAM details, architecture |
| `scripts/` | Legacy setup script (superseded by Terraform) |
| `plans/` | Implementation plans |

## Remote State

State is stored in OCI Object Storage — `tfstate` bucket in namespace `axvczntoncvg` (region `ap-melbourne-1`). Each root module uses a distinct state key:

| Module | State key |
|--------|-----------|
| VCN | `terraform/vcn/terraform.tfstate` |
| Instances | `terraform/instances/terraform.tfstate` |
| Bastion | `terraform/bastion/terraform.tfstate` |
| Budget | `terraform/budget/terraform.tfstate` |

A missing backend key defaults to `terraform.tfstate` and silently collides with other modules — every root module must set an explicit `key` in its `backend "oci"` block.

## Quick Start

```bash
terraform -chdir=terraform/vcn init && terraform -chdir=terraform/vcn apply
terraform -chdir=terraform/instances init && terraform -chdir=terraform/instances apply
terraform -chdir=terraform/bastion init && terraform -chdir=terraform/bastion apply
terraform -chdir=terraform/budget init && terraform -chdir=terraform/budget apply
```

No `.tfvars` committed. Set variables via environment or CLI flags. See [docs/getting-started.md](docs/getting-started.md) for full setup.

## Documentation

- [Getting Started](docs/getting-started.md) — setup walkthrough and access guide
- [Access Control](docs/access-control.md) — identity domains, policies, agent access
- [Archived Setup Guide](docs/setup-guide-archived.md) — legacy manual OCI console steps (superseded by Terraform)

## Verification

Module documentation was verified against live OCI state using:
- **Terraform Registry** (`oracle/oci` 8.24.0) — all 15 resource types and data sources confirmed, attributes compatible
- **Terraform Best Practices** — README structure and naming conventions validated
- **OCI Identity MCP** — tenancy `hello17`, compartment `Comp-1`, AD `KfOu:AP-MELBOURNE-1-AD-1` confirmed
- **OCI Compute MCP** — image OCID and instance shapes confirmed
- **OCI Networking MCP** — VCN `172.16.0.0/20`, subnet `172.16.0.0/24`, security lists confirmed
