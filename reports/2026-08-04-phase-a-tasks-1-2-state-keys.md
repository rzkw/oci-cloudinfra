# Report: Phase A Tasks 1 & 2 — restore distinct per-module state keys

Date: 2026-08-04

Plan: `plans/2026-08-04-restore-terraform-state-keys.md` (approved by admin via
PR #59, merged 2026-08-04)

PR: this PR (branch `fix/terraform-phase-a-state-keys`)

## Tasks completed

Phase A, Task 1 — `AGENTS.md`: plan-approval + references + backend-key policy
- Added a "Plan approval & references" section under Required Workflow: no major
  plans implemented without admin approval; plans require PR review first; every
  plan/report includes a References section (official docs + personal/engineering
  blogs only, never academic papers); plans under `plans/`, reports under
  `reports/` referencing plan/PR/commits.
- Added a Project Structure note: each root module's `backend "oci"` block must
  set a distinct `key` (`terraform/<module>/terraform.tfstate`); a missing key
  defaults to `terraform.tfstate` and silently collides with other modules.

Phase A, Task 2 — restore distinct backend keys
- `terraform/instances/providers.tf`: added `key = "terraform/instances/terraform.tfstate"`
  and `region = "ap-melbourne-1"` to the existing `backend "oci"` block.
- `terraform/vcn/main.tf`: added `key = "terraform/vcn/terraform.tfstate"` and
  `region = "ap-melbourne-1"` to the existing `backend "oci"` block.
- `terraform/budget/providers.tf`: added a `backend "oci"` block with
  `key = "terraform/budget/terraform.tfstate"` and `region = "ap-melbourne-1"`.

Resulting keys: `terraform/vcn/terraform.tfstate`,
`terraform/instances/terraform.tfstate`, `terraform/budget/terraform.tfstate`.

## Additional change (approved during PR review)

Removed `terraform/budget/plan.tf` — a corrupted `terraform plan -out` artifact
(zip data) accidentally committed in `e7ab7a9`. It broke `terraform fmt -check`
and budget module validation (and would have failed the PR CI fmt job
`.github/workflows/lint.yml`). Added `*.tfplan` to `.gitignore` to prevent
recurrence. No valid Terraform config content was lost.

## Verification

- `terraform fmt -check -recursive terraform/` — pass.
- `terraform -chdir=terraform/vcn init -backend=false && terraform -chdir=terraform/vcn validate` — pass.
- Same for `instances` and `budget` — pass.

## Not done (deferred per admin)

Phase A Task 3 (VCN bastion/service-gateway removal) and Task 4 (README.md /
docs/index.md) are NOT part of this PR. Phase B state operations run on the
deploy machine after Phase A merges.

## References

- [Terraform backend configuration](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)
- [OCI provider: backend "oci" / Object Storage state storage](https://registry.terraform.io/providers/oracle/oci/latest/docs/guides/remote_backend)
- [Terraform init: -migrate-state vs -reconfigure](https://developer.hashicorp.com/terraform/cli/commands/init)
- [Terraform Best Practices: state file design](https://www.terraform-best-practices.com/state-file-design)
- [ansible PR #28: Tailscale-only SSH, no bastion](https://github.com/rzkw/ansible/pull/28)
