# Plan: Fix Terraform MCP + Simplify Instances Module

Date: 2026-08-29
Status: Approved (this plan)

## Goal

1. Restore Terraform MCP server connectivity (was failing to start).
2. Massively simplify `terraform/instances/` to deploy a single instance with
   its boot volume only — no `count`/loops, no block volumes, default AD.

## 1. Terraform MCP connectivity

Diagnosis: `opencode.json` runs the official HashiCorp Docker image
`hashicorp/terraform-mcp-server:1.0.0`. The server never connected because
(verified) the **rootless Docker daemon was not running**
(`/home/laborant/.docker/run/docker.sock` symlink target `/run/user/1001/docker.sock`
absent) and the image was not pulled. A stale systemd unit
`terraform-mcp.service` was stuck auto-restarting against the rootful socket
`/var/run/docker.sock`.

Fix (official vendor image only):
- `systemctl --user start docker` (rootless daemon).
- `docker pull hashicorp/terraform-mcp-server:1.2.0`.
- Update `opencode.json` image tag `1.0.0` → `1.2.0`.
- Stop/disable the stale `terraform-mcp.service`.
- Restart opencode so the `terraform` MCP tools load.

## 2. Instances module simplification (ponytail full)

`terraform/instances/main.tf` (129 → ~75 lines):
- Drop `oci_identity_availability_domains` data source; use
  `var.availability_domain` (default `KfOu:AP-MELBOURNE-1-AD-1`).
- Remove `count` from `oci_core_instance`; single `subnet_ocid`.
- `agent_config`: keep only Bastion, Compute Instance Monitoring, Compute
  Instance Run Command, Vulnerability Scanning (all ENABLED); drop the other 6.
- Remove `oci_core_volume` + `oci_core_volume_attachment` (block storage).
- Remove `locals` for-expression.

`variables.tf`: remove `instance_count`, `block_storage_sizes_in_gbs`,
`subnet_ocids`; add `availability_domain` and `subnet_ocid`.
`outputs.tf`: single non-list `instance_ocid` / `instance_private_ip`.

## Budget check

Live budget ("Dollar-Budget"): **AUD 1.00/month** (read via read-only OCI CLI).
VM.Standard.A1.Flex at 4 OCPU / 24 GB is **Always Free** → compute **AUD 0**.
50 GB boot volume is within the Always Free 200 GB block-storage allowance →
**AUD 0**. Total estimated change: **AUD 0/month** (removes optional paid block
volumes which default to empty). Within budget.

## References

- HashiCorp Terraform MCP server deploy docs: https://developer.hashicorp.com/terraform/mcp-server
- hashicorp/terraform-mcp-server Docker official image tags:
  https://hub.docker.com/r/hashicorp/terraform-mcp-server/tags
- Oracle Cloud Always Free resources (A1.Flex 4 OCPU/24 GB, 200 GB block
  storage): https://www.oracle.com/cloud/free/
- OCI pricing MCP server (AUD), block volume SKU `B91961` = AUD 0.03825/GB/mo.
- Terraform Best Practices code-styling (pre-commit hooks):
  https://www.terraform-best-practices.com/code-styling
