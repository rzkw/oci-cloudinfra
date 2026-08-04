# Plan: Restore distinct per-module Terraform state keys

Date: 2026-08-04

Status: AWAITING ADMIN APPROVAL — do not execute any part of this plan
(Phase A code or Phase B state operations) until an admin approves this
document. A prior attempt executed Phase A commits without approval; they
were removed. This plan is the single source of truth for the approved work.

## Plan modifications by @rzkw (PR #59 review)

Round 1:
- **Task "Guard against key collisions" removed**: do not implement the
  backend-key guard script / pre-commit hook / CI job — too many features to
  maintain.
- **Task 3.5 revised**: reports (after completion, during WIP, etc.) are saved
  under `reports/` and reference the plan, PR, and commits. Plans remain under
  `plans/`. References wording per @rzkw below.

Round 2:
- **"Restore destroyed VCN resources" removed**: do NOT reinstate the bastion,
  service gateway, or service-gateway route rule. Access is Tailscale-only SSH
  (no bastion, no public port 22) — see
  https://github.com/rzkw/ansible/pull/28. Phase A therefore *removes* the
  bastion + service gateway + related route rule from the VCN module config;
  Phase B reconciles state so the already-destroyed resources are not recreated.
- **AGENTS.md rewrite moved to Task 1** (same ordering as ansible PR #28):
  the plan-approval + references policy lands first.

## Global constraints

- **Approval gate**: no Phase A code changes and no Phase B state operations
  run until an admin reviews and approves this plan in writing.
- **Phase B only on the deploy machine** (rizky credentials). This VM's agents
  identity is read-only on the state bucket.
- **Phase B only after Phase A merges.** The backend-key fix must be in `main`
  before any `-migrate-state` / apply / destroy operations.
- The backend-key requirement and the approval gate are permanent policy,
  written into `AGENTS.md` by Task 1.
- Access model going forward: Tailscale-only SSH. Bastion, service gateway, and
  the service-gateway route rule are not reinstated.

## Problem

`terraform destroy` run in `terraform/instances/` on the deploy machine destroyed
VCN resources (service gateway, bastion, service-gateway route rule) instead of
instance resources.

Root cause: commit `6fbfb57` ("chore: address PR #46 review feedback",
2026-07-23) removed `key = "terraform/instances/terraform.tfstate"` and `region`
from `terraform/instances/providers.tf`. The OCI Object Storage backend defaults
`key` to `terraform.tfstate`, and the `vcn` module never set an explicit key —
so both modules read/write the same state object. Not a provider-version issue.

State bucket: `tfstate` (namespace `axvczntoncvg`, region `ap-melbourne-1`).
Only one object currently exists: `terraform.tfstate` (versioning enabled).

## Current live state (verified via OCI CLI, Comp-1)

Destroyed: service gateway, bastion, service-gateway route rule. **These stay
destroyed** — not reinstated (Tailscale-only SSH).

Survived: VCN, dev subnet, internet gateway, route table, security list,
instance "VM" (`ocid1.instance.oc1.ap-melbourne-1.anwwkljrhlgazfqcuidkv4qwoqqmwxlkkstmvq6yofczd6cgv7cwoxgdbsnq`,
172.16.0.12, VM.Standard.A1.Flex, AD-1, boot volume attached) + block volume.

Credentials split: this machine's agents identity is read-only on the state
bucket (`tfstate-bucket` policy grants manage only to rizky). All state
operations in Phase B run on the deploy machine with rizky credentials.

## Phase A — Code (this repo, this PR)

Goal: make it impossible for two modules to silently share backend state again,
and drop the abandoned bastion/service-gateway resources from the VCN config.

### Task 1 — AGENTS.md: plan-approval + references + backend-key policy

Same as ansible PR #28 (https://github.com/rzkw/ansible/pull/28). Modify
`AGENTS.md` under Required Workflow:

- **Plan approval**: never implement major plans without approval from the repo
  admin/code owner; major changes require the plan to be submitted for PR
  review before any implementation.
- **Plans and reports**: all plans and reports MUST include a **References**
  section citing sources for every design decision (libraries, services,
  runtime behavior, security controls). Acceptable sources: official product
  documentation, personal blogs from engineers/devs/sysadmins, and product
  engineering blogs. Academic papers are never acceptable.
- Plans are saved under `plans/` with a dated filename. Reports (after
  completion, during WIP, etc.) are saved under `reports/` and reference the
  plan, PR, and commits.
- **Backend keys**: each root module's `backend "oci"` block must set a distinct
  `key` (`terraform/<module>/terraform.tfstate`); a missing key defaults to
  `terraform.tfstate` and silently collides with other modules.

### Task 2 — Restore distinct backend keys

- `terraform/instances/providers.tf`: add back `key = "terraform/instances/terraform.tfstate"`
  and `region = "ap-melbourne-1"` to the existing `backend "oci"` block.
- `terraform/vcn/main.tf`: add `key = "terraform/vcn/terraform.tfstate"` and
  `region = "ap-melbourne-1"` to the existing `backend "oci"` block.
- `terraform/budget/providers.tf`: add a `backend "oci"` block with
  `key = "terraform/budget/terraform.tfstate"` and `region = "ap-melbourne-1"`.

Resulting keys: `terraform/vcn/terraform.tfstate`,
`terraform/instances/terraform.tfstate`, `terraform/budget/terraform.tfstate`.

### Task 3 — VCN: remove bastion + service gateway (not reinstated)

In `terraform/vcn/main.tf`:
- Remove `data "oci_core_services" "all_mel"` (only used by SG + SG route rule).
- Remove `resource "oci_core_service_gateway" "internal"`.
- Remove the `route_rules` block pointing `SERVICE_CIDR_BLOCK` at the service
  gateway (keep the `0.0.0.0/0` IGW rule).
- Remove `resource "oci_bastion_bastion" "this"` and
  `resource "oci_bastion_session" "managed_ssh"`.

In `terraform/vcn/variables.tf`:
- Remove `bastion_client_cidrs`, `target_instance_ocid`,
  `target_instance_private_ip`, `bastion_session_ssh_public_key`.

### Task 4 — Docs

- `README.md` (Remote State section): document per-module state keys.
- `docs/index.md`: update state/notes section.

## Phase B — Operations runbook (deploy machine, rizky creds)

Run only after Phase A is merged. This VM's identity is read-only on the state
bucket, so these steps use the deploy machine.

### Task 5 — Preflight

- On deploy machine, pull `main`, `terraform -chdir=terraform/<module> init` per module.
- Confirm module provider lockfiles all resolve (vcn/instances 8.22.x, budget 8.25.x).
- Verify state bucket holds exactly one object (`terraform.tfstate`).
- Snapshot block volume of orphan instance before any teardown.

### Task 6 — Migrate VCN state to its own key

- `terraform -chdir=terraform/vcn init -migrate-state`.
- Verify `terraform state list` matches live VCN resources; confirm no instance
  or volume resources in VCN state.

### Task 7 — Reconcile VCN state (no recreation)

- `terraform -chdir=terraform/vcn plan` and review diff: bastion, service
  gateway, and SG route rule are removed from state (they no longer exist in
  the tenancy); VCN, dev subnet, internet gateway, route table, and security
  list are untouched.
- `terraform apply`.
- Verify: no bastion/SG in `terraform state list`; VCN/subnet/IGW/route
  table/security list still present.

### Task 8 — Terminate orphan instance, rebuild from scratch

- `terraform -chdir=terraform/instances init -reconfigure` (NOT `-migrate-state`
  — the shared state still contains VCN resources and must not be adopted).
- Terminate orphan instance via OCI CLI with `--preserve-boot-volume false --force`.
- `terraform apply` to recreate the instance, block volume, volume attachment,
  and backup policy assignment from scratch.
- Confirm instance reachable via Tailscale (no bastion, no public port 22) and
  no leftover boot volume.

### Task 9 — Migrate budget state to its own key

- `terraform -chdir=terraform/budget init -migrate-state`.

### Task 10 — Verify

- State bucket contains exactly three objects under `terraform/` with the
  expected keys and no stale `terraform.tfstate`.
- `terraform state list` in each module shows only its own resources.
- No billing/resources outside budget ($1/month).
- Rotate the Tailscale auth key that lived in the orphaned local state backup;
  keep that backup offline (contains SSH keys + tailscale auth).

## Ponytail evaluation

Alternative: scrap the VCN and re-apply everything from scratch. Rejected —
the VCN itself is intact and destroying it adds real teardown risk with zero
benefit. Both approaches require the state-separation fix. The only
recreate-from-scratch component is the instance, which Task 8 already does.
The bastion + service gateway are dropped rather than restored because access
is now Tailscale-only SSH (no bastion) per ansible PR #28.

## Risks

- `-migrate-state` in Task 6 adopts the shared state; must not be run for
  `instances` (Task 8 uses `-reconfigure`). Verified ordering.
- Removing the SG route rule + service gateway from config deletes them from
  state — they are already destroyed in the tenancy, so apply is non-destructive
  for live resources.
- Budget lockfile (8.25.0) differs from vcn/instances (8.22.0) — known drift,
  out of scope.
- Tailscale-only SSH means no fallback SSH path if Tailscale is down — accepted
  per ansible PR #28 direction.

## References

- [Terraform backend configuration](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)
- [Terraform init: -migrate-state vs -reconfigure](https://developer.hashicorp.com/terraform/cli/commands/init)
- [OCI provider: backend "oci" / Object Storage state storage](https://registry.terraform.io/providers/oracle/oci/latest/docs/guides/remote_backend)
- [OCI Object Storage: working with buckets and objects](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/managingbuckets.htm)
- [OCI Compute: terminating instances (boot volume behavior)](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/stopping-compute-instance.htm)
- [OCI CLI: oci compute instance terminate](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/compute/instance/terminate.html)
- [Terraform Best Practices: state file design](https://www.terraform-best-practices.com/state-file-design)
- [ansible PR #28: Tailscale-only SSH, no bastion](https://github.com/rzkw/ansible/pull/28)
- [Tailscale: access Oracle Cloud VMs privately](https://tailscale.com/docs/install/cloud/oracle-cloud)

## Execution order (this PR)

1. Plan file (this document) + Task 1 AGENTS.md policy — **approved first**
2. Task 2 backend keys
3. Task 3 VCN bastion/SG removal
4. Task 4 docs
5. Commit, push, open PR
6. Phase B after merge (deploy machine, admin-approval gate met via this plan)
