# Terraform

Four independent root modules, each with its own state.

| Module | Purpose |
|--------|---------|
| [vcn/](vcn/) | VCN, subnet, routing, security lists |
| [instances/](instances/) | A1.Flex compute, cloud-init, block volumes |
| [bastion/](bastion/) | Managed OCI Bastion + SSH session (reads vcn/instances state) |
| [budget/](budget/) | $1/month cost alerts via email |

## Quick Start

```bash
terraform -chdir=vcn init && terraform -chdir=vcn apply
terraform -chdir=instances init && terraform -chdir=instances apply
terraform -chdir=bastion init && terraform -chdir=bastion apply
terraform -chdir=budget init && terraform -chdir=budget apply
```

Deploy in order: Budget first, then VCN (provides subnet OCID), then instances, then bastion (reads both states). Destroy in reverse order.

## Remote State

All modules use OCI Object Storage backend — `tfstate` bucket in namespace `axvczntoncvg`. Each module maintains its own state file.

## Variables

No `.tfvars` committed. Set variables via environment:

```bash
export TF_VAR_compartment_ocid="ocid1.compartment.oc1..aaaaaaaa..."
export TF_VAR_tenancy_ocid="ocid1.tenancy.oc1..aaaaaaaa..."
```

See each module's `variables.tf` for the full list.
