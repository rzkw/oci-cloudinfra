# Split Bastion into Its Own Root Module

Date: 2026-08-21

Status: AWAITING ADMIN APPROVAL

Supersedes the bastion wiring from `plans/2026-08-20-merge-bastion-into-vcn.md`.
All infra (VCN, bastion, instance) was destroyed on 2026-08-21 after a failed
access attempt; this is a clean rebuild.

## Problem

Merging the bastion into `terraform/vcn` created a Terraform cycle
(bastion → subnet → security_list → bastion) when referencing the bastion
private endpoint IP in the security list. The shipped workaround — a dynamic
rule gated on `var.bastion_private_ip`, set by a manual second apply — was
never run, so no SSH ingress rule existed and managed SSH sessions
authenticated but could not reach the instance. The flow also required copying
the instance OCID into tfvars after every instance recreation, which fed a dead
target OCID to a live session.

## Approach

Adopt the three-root-module pattern (network / compute / bastion) with
`terraform_remote_state` data sources. No dynamic blocks; single-user,
single-instance assumptions are explicit.

## Changes

### 1. terraform/vcn

- Remove `oci_bastion_bastion`, `oci_bastion_session`; remove vars
  `target_resource_id`, `bastion_public_key`, `client_cidr_block_allow_list`,
  `bastion_private_ip`; remove output `bastion_private_endpoint_ip`.
- Replace the dynamic rule with a static ingress: TCP/22 from
  `var.dev_subnet_cidr` (default `172.16.0.0/24`), also used by
  `oci_core_subnet.dev.cidr_block`. The bastion endpoint lives in that subnet,
  so its traffic sources within it — same-subnet SSH rule as the reference.
  No cycle, single apply.

### 2. terraform/instances

No code change; existing output `instance_ocids` is consumed by bastion.

### 3. terraform/bastion (new)

- `providers.tf`: OCI backend key `terraform/bastion/terraform.tfstate`
  (distinct — avoids the state-key collision class of bug), `oci ~> 8.20`
  matching vcn.
- `data "terraform_remote_state"` for vcn (`dev_subnet_ocid`) and instances
  (`instance_ocids[0]`).
- `oci_bastion_bastion`: STANDARD, `target_subnet_id` from vcn state,
  `client_cidr_block_allow_list` default `["0.0.0.0/0"]`.
- `oci_bastion_session`: MANAGED_SSH, ubuntu:22, `session_ttl_in_seconds`
  10800, `key_details.public_key_content = var.bastion_public_key`.
- Output `connection_details` =
  `oci_bastion_session.managed_ssh.ssh_metadata.command`.
- `.terraform-docs.yml` + root README table/markers so the docs workflow picks
  up the new module.

## Apply order

vcn → instances → bastion; destroy in reverse. No manual steps between applies.

## Verification

1. `terraform fmt -check -recursive terraform/`
2. Validate all three modules with `-backend=false`
3. Budget check per AGENTS.md (bastion service is free; A1 instance vs $1/mo)
4. Apply from operator laptop (tfvars + backend creds live there); run the
   `connection_details` output verbatim; expect a shell on ubuntu@<private-ip>
5. CI green (lint, Checkov, terraform-docs)

## References

- Three-module pattern, same-subnet SSH rule, `ssh_metadata.command` output:
  https://martincarstenbach.com/2021/11/12/create-an-oci-bastion-service-via-terraform/
- Remote state data source:
  https://developer.hashicorp.com/terraform/language/state/remote-state-data
- Managed SSH sessions propagate the session key to the target:
  https://docs.oracle.com/en-us/iaas/Content/Bastion/Tasks/create-session-managed-ssh.htm
- OCI backend:
  https://developer.hashicorp.com/terraform/language/backend/oci
