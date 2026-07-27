# README + Docs Restructure Plan

> Branch: `docs/readme-restructure`
> Date: 2026-07-27

## Goal

Rewrite README files (root, terraform/, per-module) and rename `wiki/` to `docs/` with proper filenames. Remove wiki artifacts. Update CI to preserve module READMEs.

## Requirements

1. Root README — brief project overview, resource table, remote state backend note, link to `docs/`
2. `terraform/README.md` — module overview, quick start, remote state note
3. Module READMEs — brief desc + curated variables/outputs (no `Required` column, no sensitive values, no null/never-set vars)
4. `wiki/` → `docs/` with renamed files, delete `_Footer.md`/`_Sidebar.md`
5. CI workflow updated to stop deleting module READMEs
6. All internal links updated

## Variable audit

### Excluded (sensitive)
- `bastion_session_ssh_public_key` (VCN)
- `tailscale_auth_key` (Instances)

### Excluded (null, never set)
- `freeform_tags` (Instances)
- `defined_tags` (Instances)
- `ssh_public_keys` (Instances)

### Outputs excluded
- `vcn_state` — informational, not consumed
- `dev_subnet_cidr` — informational, not consumed
- `dev_subnet_ocid` — excluded per user request
- `instance_ocids` — excluded per user request
- `instance_flex` — summary string, not consumed

### Outputs included
- `vcn_cidr` (VCN)
- `instance_private_ips` (Instances)

## Files to modify

| File | Action |
|------|--------|
| `README.md` | Rewrite |
| `terraform/README.md` | Create |
| `terraform/vcn/README.md` | Rewrite |
| `terraform/instances/README.md` | Rewrite |
| `terraform/budget/README.md` | Rewrite |
| `.github/workflows/terraform-docs.yml` | Edit — remove `os.remove(mod_readme)` |
| `wiki/` → `docs/` | Move + rename 4 files, delete 2 |
| `AGENTS.md` | Edit — `wiki/` → `docs/` |

## Verification

1. `terraform fmt -check -recursive terraform/`
2. `terraform -chdir=terraform/vcn validate -backend=false` (×3 modules)
3. All `docs/` relative links resolve
4. `<!-- BEGIN_TF_DOCS -->` markers present in module READMEs
5. CI workflow no longer deletes module READMEs
6. No sensitive values in any README
7. No `Required` column in variable tables
