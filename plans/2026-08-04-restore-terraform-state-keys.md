# Plan: Restore distinct per-module Terraform state keys

Date: 2026-08-04

Status: AWAITING ADMIN APPROVAL — do not execute any part of this plan
(Phase A code or Phase B state operations) until an admin approves this
document. A prior attempt executed Phase A commits without approval; they
were removed. This plan is the single source of truth for the approved work.

## Plan modifications by @rzkw (PR #59 review)

- **Task 2 removed**: do not implement the backend-key guard script / pre-commit
  hook / CI job — too many features to maintain.
- **Task 3.5 revised**: reports (after completion, during WIP, etc.) are saved
  under `reports/` and reference the plan, PR, and commits. Plans remain under
  `plans/`. References wording per @rzkw below.

## Global constraints

- **Approval gate**: no Phase A code changes and no Phase B state operations
  run until an admin reviews and approves this plan in writing.
- **Phase B only on the deploy machine** (rizky credentials). This VM's agents
  identity is read-only on the state bucket.
- **Phase B only after Phase A merges.** The backend-key fix must be in `main`
  before any `-migrate-state` / apply / destroy operations.
- The backend-key requirement and the approval gate are permanent policy,
  written into `AGENTS.md` by Task 3.5.

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

Destroyed: service gateway, bastion, service-gateway route rule.

Survived: VCN, dev subnet, internet gateway, route table, security list,
instance "VM" (`ocid1.instance.oc1.ap-melbourne-1.anwwkljrhlgazfqcuidkv4qwoqqmwxlkkstmvq6yofczd6cgv7cwoxgdbsnq`,
172.16.0.12, VM.Standard.A1.Flex, AD-1, boot volume attached) + block volume.

Credentials split: this machine's agents identity is read-only on the state
bucket (`tfstate-bucket` policy grants manage only to rizky). All state
operations in Phase B run on the deploy machine with rizky credentials.

## Phase A — Code (this repo, this PR)

Goal: make it impossible for two modules to silently share backend state again.

### Task 1 — Restore distinct backend keys

- `terraform/instances/providers.tf`: add back `key = "terraform/instances/terraform.tfstate"`
  and `region = "ap-melbourne-1"` to the existing `backend "oci"` block.
- `terraform/vcn/main.tf`: add `key = "terraform/vcn/terraform.tfstate"` and
  `region = "ap-melbourne-1"` to the existing `backend "oci"` block.
- `terraform/budget/providers.tf`: add a `backend "oci"` block with
  `key = "terraform/budget/terraform.tfstate"` and `region = "ap-melbourne-1"`.

Resulting keys: `terraform/vcn/terraform.tfstate`,
`terraform/instances/terraform.tfstate`, `terraform/budget/terraform.tfstate`.

### Task 2 — Guard against key collisions

**REMOVED per @rzkw PR #59 review** — too many features to maintain. No guard
script, no pre-commit hook, no CI job. The per-module keys are enforced by
manual review of the backend blocks (single source of truth: Task 1).

### Task 3 — Docs

- `README.md` (Remote State section): document per-module state keys.
- `docs/index.md`: update state/notes section.
- `AGENTS.md` Project Structure: note that each module must define a distinct
  backend key.

### Task 3.5 — Planning references + approval gate (user requirement)

`AGENTS.md`: add a "Plans and reports" rule under Required Workflow:

- All plans and reports MUST include a **References** section citing sources
  for every design decision (libraries, services, runtime behavior, security
  controls). Acceptable sources: official product documentation, personal blogs
  from engineers/devs/sysadmins, and product engineering blogs. Academic papers
  are never acceptable.
- Plans are saved under `plans/` with a dated filename.
- Reports (after completion, during WIP, etc.) are saved under `reports/` and
  reference the plan, PR, and commits.
- **Approval gate**: no major plan (state operations, resource destruction,
  multi-module changes) may be executed until an admin approves the written
  plan.

## Phase B — Operations runbook (deploy machine, rizky creds)

Run only after Phase A is merged. This VM's identity is read-only on the state
bucket, so these steps use the deploy machine.

### Task 4 — Preflight

- On deploy machine, pull `main`, `terraform -chdir=terraform/<module> init` per module.
- Confirm module provider lockfiles all resolve (vcn/instances 8.22.x, budget 8.25.x).
- Verify state bucket holds exactly one object (`terraform.tfstate`).
- Snapshot block volume of orphan instance before any teardown.

### Task 5 — Migrate VCN state to its own key

- `terraform -chdir=terraform/vcn init -migrate-state`.
- Verify `terraform state list` matches live VCN resources; confirm no instance
  or volume resources in VCN state.

### Task 6 — Restore destroyed VCN resources

- `terraform -chdir=terraform/vcn plan` and review diff (recreates service
  gateway, bastion, service-gateway route rule).
- Apply with `-var target_instance_ocid=null -var target_instance_private_ip=null`
  so bastion is created without a target.
- Verify: service gateway active, bastion created, route rule present.

### Task 7 — Terminate orphan instance, rebuild from scratch

- `terraform -chdir=terraform/instances init -reconfigure` (NOT `-migrate-state`
  — the shared state still contains VCN resources and must not be adopted).
- Terminate orphan instance via OCI CLI with `--preserve-boot-volume false --force`.
- `terraform apply` to recreate the instance, block volume, volume attachment,
  and backup policy assignment from scratch.
- Confirm instance reachable (SSH/Tailscale) and no leftover boot volume.

### Task 8 — Migrate budget state to its own key

- `terraform -chdir=terraform/budget init -migrate-state`.

### Task 9 — Verify

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
recreate-from-scratch component is the instance, which Task 7 already does.

## Risks

- `-migrate-state` in Task 5 adopts the shared state; must not be run for
  `instances` (Task 7 uses `-reconfigure`). Verified ordering.
- Bastion recreation requires null bastion target vars to avoid coupling to the
  terminated instance.
- Budget lockfile (8.25.0) differs from vcn/instances (8.22.0) — known drift,
  out of scope.

## References

- [Terraform backend: "local"](https://developer.hashicorp.com/terraform/language/settings/backends/local)
- [Terraform backend configuration](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)
- [Terraform init: -migrate-state vs -reconfigure](https://developer.hashicorp.com/terraform/cli/commands/init)
- [OCI provider: backend "oci" / Object Storage state storage](https://registry.terraform.io/providers/oracle/oci/latest/docs/guides/remote_backend)
- [OCI Object Storage: working with buckets and objects](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/managingbuckets.htm)
- [OCI Compute: terminating instances (boot volume behavior)](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/stopping-compute-instance.htm)
- [OCI CLI: oci compute instance terminate](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/compute/instance/terminate.html)
- [Terraform Best Practices: state file design](https://www.terraform-best-practices.com/state-file-design)
- [pre-commit-terraform (terraform_fmt, terraform_validate hooks)](https://github.com/antonbabenko/pre-commit-terraform)

## Execution order (this PR)

1. Plan file (this document) + Task 3.5 AGENTS.md rule — **approved first**
2. Task 1 backend keys
3. Task 3 docs
4. Commit, push, open PR
5. Phase B after merge (deploy machine, admin-approval gate met via this plan)
