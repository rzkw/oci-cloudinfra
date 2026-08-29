# Report: Fix Terraform MCP + Simplify Instances Module

Date: 2026-08-29
Plan: `plans/2026-08-29-simplify-instances-mcp.md`

## Terraform MCP connectivity — fixed

Root cause: rootless Docker daemon wasn't running and the official image wasn't
pulled; a stale systemd unit pointed at the rootful socket. Actions taken:
- Started rootless daemon: `systemctl --user start docker` (docker info OK).
- Pulled official image: `docker pull hashicorp/terraform-mcp-server:1.2.0`.
- `opencode.json`: tag `1.0.0` → `1.2.0` (official HashiCorp image only).
- Stopped/disabled stale `terraform-mcp.service`.
- Verified the image serves the registry toolset over stdio (initialize
  handshake returned serverInfo `terraform-mcp-server 1.2.0`).

Note: opencode must be **restarted** to load the `terraform` MCP tools (config
is read at startup, not hot-reloaded). This run's checks used the OCI MCP
servers + CLI; `validate` passed independently.

## Instances module simplification — done

`terraform/instances/` now deploys a single instance + boot volume:

- main.tf: 129 → 64 lines. Removed AD data source (default
  `KfOu:AP-MELBOURNE-1-AD-1` via `availability_domain` variable), removed
  `count`, `oci_core_volume`, `oci_core_volume_attachment`, and the `locals`
  for-expression. `agent_config` trimmed from 10 plugins to Bastion, Compute
  Instance Monitoring, Compute Instance Run Command, Vulnerability Scanning.
- variables.tf: removed `instance_count`, `block_storage_sizes_in_gbs`,
  `subnet_ocids`; added `availability_domain`, `subnet_ocid`.
- outputs.tf: `instance_ocid`, `instance_private_ip` (single, non-list).

Verification passed: `terraform fmt -check -recursive terraform/instances` and
`terraform -chdir=terraform/instances validate` (after `init -backend=false`).
`.terraform.lock.hcl` gained one provider zip hash from init (benign).

## Budget

Live budget ("Dollar-Budget") = **AUD 1.00/month** (read via read-only OCI CLI).
A1.Flex 4 OCPU/24 GB and 50 GB boot volume are Always Free → **AUD 0**.
This change removes optional paid block volumes (default empty). Estimated
impact **AUD 0/month** — within budget.

## References
- HashiCorp Terraform MCP server docs: https://developer.hashicorp.com/terraform/mcp-server
- Official image tags: https://hub.docker.com/r/hashicorp/terraform-mcp-server/tags
- Oracle Cloud Always Free: https://www.oracle.com/cloud/free/
- Terraform Best Practices code-styling: https://www.terraform-best-practices.com/code-styling
