# Phase B: Destroy & Recreate — State Reset

Date: 2026-08-04

Status: AWAITING ADMIN APPROVAL

Depends on: Plan `plans/2026-08-04-restore-terraform-state-keys.md`, PRs #59, #60, #61 (all merged)

## Problem

Phase A fixed backend keys and removed bastion/service gateway from config. But the OCI bucket still holds a stale state file at the old flat key (`terraform.tfstate`), and existing OCI resources (VCN, subnet, instance, etc.) have no Terraform state tracking them. `terraform init` fails because the bucket object doesn't match the new namespaced key.

## Approach

Delete old state from the bucket, init fresh, destroy orphaned OCI resources via CLI, then `terraform apply` to recreate.

## Steps

### 1. Clean the state bucket (OCI CLI)

```bash
oci os object delete --bucket-name tfstate --namespace axvczntoncvg --name terraform.tfstate --force
oci os object delete --bucket-name tfstate --namespace axvczntoncvg --name terraform.tfstate.lock --force
oci os object delete --bucket-name tfstate --namespace axvczntoncvg --name terraform/vcn/terraform.tfstate.lock --force
```

### 2. Init all modules

```bash
terraform -chdir=terraform/vcn init
terraform -chdir=terraform/instances init
terraform -chdir=terraform/budget init
```

### 3. Destroy OCI resources via CLI (no state exists — `terraform destroy` finds nothing)

Delete in dependency order:

| Order | Resource | OCID suffix | Command |
|-------|----------|-------------|---------|
| 1 | Instance | `bsnq` | `oci compute instance terminate --instance-id ... --force` |
| 2 | Subnet | `qaiqq2a` | `oci network subnet delete --subnet-id ... --force` |
| 3 | IGW | `lgfea` | `oci network internet-gateway delete --ig-id ... --force` |
| 4 | Route Table | `pwantpaa` | `oci network route-table delete --rt-id ... --force` |
| 5 | Security List | `qphya` | `oci network security-list delete --sl-id ... --force` |
| 6 | DHCP Options | `dw23q3sa` | `oci network dhcp-options delete --dhcp-id ... --force` |
| 7 | VCN | `x2ucxaa` | `oci network vcn delete --vcn-id ... --force` |
| 8 | Budget | `saleq` | `oci budgets budget budget delete --budget-id ... --force` |

### 4. Deploy fresh

```bash
terraform -chdir=terraform/vcn apply -auto-approve
terraform -chdir=terraform/instances apply -auto-approve
terraform -chdir=terraform/budget apply -auto-approve
```

### 5. Verify

- `terraform -chdir=terraform/vcn state list` — shows VCN, IGW, route table, security list, subnet
- `terraform -chdir=terraform/instances state list` — shows instance
- `terraform -chdir=terraform/budget state list` — shows budget + alert rules
- `oci os object list --bucket-name tfstate --namespace axvczntoncvg` — shows 3 distinct state keys

## Risk

Instance data loss is permanent (user confirmed acceptable).

## References

- OCI CLI: compute instance terminate — https://docs.oracle.com/en-us/iaas/Tools/CLI/latest/cli3/compute-cli/reference/cli_cli_reference/compute/instance/terminate.htm
- OCI CLI: network subnet delete — https://docs.oracle.com/en-us/iaas/Tools/CLI/latest/cli3/network-cli/reference/cli_cli_reference/network/subnet/delete.htm
- OCI CLI: budget delete — https://docs.oracle.com/en-us/iaas/Tools/CLI/latest/cli3/budgets-cli/reference/cli_cli_reference/budgets/budget/delete.htm
- Terraform OCI backend — https://developer.hashicorp.com/terraform/language/backend/oci
