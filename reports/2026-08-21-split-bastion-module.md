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

Re-run via OCI Pricing MCP server (official `oracle/mcp`
oci-pricing-mcp-server; `ping` → ok) against the public Price List API, USD
list prices, per updated AGENTS.md (PR #77 review request):

| Item | Cost | Source |
|------|------|--------|
| OCI Bastion service | $0.00 — absent from public price list (no charge for bastions/sessions) | `pricing_search_name("Bastion", "USD")` → 0 items |
| VM.Standard.A1.Flex (≤4 OCPU/24 GB) | $0.00 — Always Free Arm allowance; A1 absent from price list (closest listed shape: A2 OCPU $0.014/h) | `pricing_search_name("Compute", "USD", require_priced=True)` |
| NAT Gateway | $0.00 fixed — absent from price list; only per-GB processing (~$0 at dev traffic) | `pricing_search_name("NAT Gateway", "USD")` → 0 items |
| **Live budget** `Dollar-Budget` | **$1.00/month cap** | `oci budgets budget budget list` (re-verified 2026-08-21) |
| Actual spend (2026-08-21) | $0.00 actual, $0.00 forecast | same |

Estimated total $0.00/month ≤ $1.00 budget → within budget, deployment may
proceed.

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
- OCI Pricing MCP server (oracle/mcp): https://github.com/oracle/mcp/tree/main/src/oci-pricing-mcp-server
