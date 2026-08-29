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

All figures in AUD. AWS = ap-southeast-2 on-demand list prices, converted at
1 USD = 1.3951 AUD (ECB reference via frankfurter.dev, 2026-08-21); monthly =
hourly × 730.

| Resource | AWS equivalent | OCI/mo | AWS/mo | OCI/yr | AWS/yr |
|----------|----------------|--------|--------|--------|--------|
| VCN (+ IGW, subnets) | VPC + IGW + subnets | A$0 | A$0 | A$0 | A$0 |
| NAT Gateway¹ | NAT Gateway + public IPv4 | A$0 | A$65.18 | A$0 | A$782.15 |
| Compute `VM.Standard.A1.Flex` (4 OCPU / 24 GB)² | EC2 `t4g.xlarge` (4 vCPU / 16 GiB) | A$0 | A$172.72 | A$0 | A$2072.69 |
| Bastion (STANDARD, MANAGED_SSH)³ | SSM Session Manager | A$0 | A$0 | A$0 | A$0 |
| Budget alerts⁴ | AWS Budgets (first 2 free) | A$0 | A$0 | A$0 | A$0 |
| **Total** | | **A$0** | **≈A$238** | **A$0** | **≈A$2855** |

¹ NAT data processing (US$0.059/GB) excluded — dev traffic negligible; row
includes the US$0.005/hr public IPv4 charge.
² AWS free tier does not cover t4g.xlarge (legacy allowance tops out at
t4g.small); full on-demand rate applied.
³ SSM Standard tier is free; OCI Bastion service and sessions are free.
⁴ OCI budgets and alert rules are free.

The entire stack sits inside OCI Always Free allowances; the equivalent AWS
resources cost ≈ **A$238/month (~A$2855/year)**.
Sources: [AWS Price List Bulk API](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonEC2/current/ap-southeast-2/index.csv)
(+ [AmazonVPC file](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonVPC/current/ap-southeast-2/index.json));
the account-scoped [Free Tier API](https://freetier.us-east-1.api.aws) requires
credentials, so published free-tier limits were used instead;
[OCI Price List API](https://apexapps.oracle.com/pls/apex/cetools/api/v1/products/).

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
- **Terraform Registry** (`oracle/oci` 8.29.0) — all 15 resource types and data sources confirmed, attributes compatible
- **Terraform Best Practices** — README structure and naming conventions validated
- **OCI Identity MCP** — tenancy `hello17`, compartment `Comp-1`, AD `KfOu:AP-MELBOURNE-1-AD-1` confirmed
- **OCI Compute MCP** — image OCID and instance shapes confirmed
- **OCI Networking MCP** — VCN `172.16.0.0/20`, subnet `172.16.0.0/24`, security lists confirmed
