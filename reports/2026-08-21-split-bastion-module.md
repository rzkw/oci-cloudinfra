# Report: Split Bastion into Own Root Module

Date: 2026-08-21

Plan: `plans/2026-08-21-split-bastion-module.md` (approved via PR #75)

Status: implemented on `feat/split-bastion-module`; deployment pending

## Changes

- **vcn**: removed `oci_bastion_bastion` + `oci_bastion_session`; removed vars
  `target_resource_id`, `bastion_public_key`, `client_cidr_block_allow_list`,
  `bastion_private_ip`; removed output `bastion_private_endpoint_ip`. Added
  `dev_subnet_cidr` (default `172.16.0.0/24`) shared by the subnet resource and
  a static TCP/22 ingress rule sourced from that CIDR.
- **bastion** (new): distinct backend key `terraform/bastion/terraform.tfstate`;
  `terraform_remote_state` reads vcn (`dev_subnet_ocid`) and instances
  (`instance_ocids[0]`); STANDARD bastion + MANAGED_SSH session (ubuntu:22,
  TTL 10800); outputs `connection_details` (`ssh_metadata.command`) and
  `session_ocid`.
- **instances**: unchanged — existing `instance_ocids` output consumed.
- **Docs**: `terraform/README.md` module table + deploy order, root README
  state table + quick start, vcn README header, new bastion README stub for
  terraform-docs.

## Verification

- `terraform fmt -check -recursive terraform/`: pass
- `validate` (vcn, instances, bastion, budget) with `-backend=false`: all pass
- CI (lint, Checkov, terraform-docs): runs on this PR

## Budget comparison

Prices in AUD (default currency per AGENTS.md), read directly from the public
Price List API (MCP pricing tools unavailable this session); live budget read
via OCI CLI, 2026-08-24:

| Item | Cost | Actual | Source | Comment |
|------|------|--------|--------|---------|
| Bastion STANDARD + MANAGED_SSH session | A$0.00 | n/a — not yet deployed | Price List API (no bastion SKU listed) | Service free per Bastion overview ref |
| VM.Standard.A1.Flex ≤ 4 OCPU / 24 GB | A$0.00 | n/a | Price List API: A1 OCPU/memory dual-priced A$0 / A$0.015 per OCPU-h (B93297/B93298) | Dev shape sits inside Always Free allowance |
| NAT Gateway | A$0.00 fixed | n/a | Price List API (no NAT SKU; APAC egress A$0 first 10 TB/mo, then A$0.0375/GB) | Dev traffic far below free allowance |
| **Live budget** `Dollar-Budget` | **$1.00/mo cap** | **$0.00 spend, $0.00 forecast** | `oci budgets budget budget list` (ACTIVE) | Monthly reset |

Estimated A$0.00/month ≤ budget → within budget, deployment may proceed.
OCI vs AWS cost comparison: see root `README.md` ("Cost Comparison").

## Deployment

From operator laptop (tfvars + backend creds): apply vcn → instances →
bastion, then `terraform -chdir=terraform/bastion output -raw
connection_details`, replace `<privateKey>`, connect.

## References

- Plan approval: https://github.com/rzkw/oci-cloudinfra/pull/75
- Pattern: https://martincarstenbach.com/2021/11/12/create-an-oci-bastion-service-via-terraform/
- Remote state data source: https://developer.hashicorp.com/terraform/language/state/remote-state-data
- Managed SSH key propagation: https://docs.oracle.com/en-us/iaas/Content/Bastion/Tasks/create-session-managed-ssh.htm
- Bastion overview (free service): https://docs.oracle.com/en-us/iaas/Content/Bastion/Concepts/bastionoverview.htm
- Always Free resources: https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Overview.htm
- OCI Price List API (AUD): https://apexapps.oracle.com/pls/apex/cetools/api/v1/products/
- List-pricing guidance: https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/signingup_topic-Estimating_Costs.htm#accessing_list_pricing
