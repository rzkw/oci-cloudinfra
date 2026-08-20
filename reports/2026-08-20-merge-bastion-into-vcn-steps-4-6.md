# Report: Merge Bastion into VCN — Steps 4–6

Date: 2026-08-20

Plan: `plans/2026-08-20-merge-bastion-into-vcn.md` (approved via PR #72,
merged 2026-08-20)

PR: #72 (plan), #73 (steps 1–3, merged 2026-08-20), this PR (steps 4–6)

## Completed (plan steps 4–6)

### Step 4 — deleted `terraform/bastion/`

- `git rm -r terraform/bastion/` — removed `main.tf`, `variables.tf`,
  `providers.tf`, `README.md`, `.terraform.lock.hcl`.
- Bastion resources now live solely in `terraform/vcn/` (single root module →
  direct references work, no cross-module state sharing).

### Step 5 — removed `instance_ad_number` from `terraform/instances/`

- Deleted `variable "instance_ad_number"` from `variables.tf`.
- Added `data "oci_identity_availability_domains" "ad"` to `main.tf` and set
  `availability_domain = data.oci_identity_availability_domains.ad.availability_domains[0].name`
  on `oci_core_instance.this` — single AD in use, fixes the number/string type
  bug.
- Block volume availability domains still derive from
  `oci_core_instance.this[...].availability_domain`, unchanged.

### Step 6 — state migration (skipped)

- Bastion was never deployed: `oci bastion bastion list --compartment-id
  ocid1.compartment.oc1..aaaaaaaau45ubk37jmbnsxmithve6745zpcu44ge4dcn3vx6dmmjozghlm6a --all`
  returns an empty list (exit 0).
- State bucket `tfstate` (namespace `axvczntoncvg`) contains only
  `terraform/budget/terraform.tfstate` and `terraform/vcn/terraform.tfstate`.
  No `terraform/bastion/` key exists, so the wrong-key collision described in
  the plan never materialized — nothing to delete or import.

## Verified

- `terraform fmt -check -recursive terraform/` — clean.
- `terraform -chdir=terraform/vcn init -backend=false && validate` — success.
- `terraform -chdir=terraform/instances init -backend=false && validate` — success.
- No lingering references to `terraform/bastion` in `.tf`, `.md`, or workflow
  files.

## Not executed

- `terraform plan` dry-run and budget pricing check — require OCI API
  credentials and pre-deploy sign-off; deferred per AGENTS.md budget workflow.
- CI `terraform-plan` job (plan review point 3) — still pending, separate
  change.

## References

- Plan: `plans/2026-08-20-merge-bastion-into-vcn.md`
- OCI AD data source: https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/identity_availability_domains
- OCI backend config: https://developer.hashicorp.com/terraform/language/backend/oci