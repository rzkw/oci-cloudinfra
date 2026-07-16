# AGENTS.md — rzkw/oci-cloudinfra

## MCP Tool Usage

Use the **Terraform MCP servers** before writing/modifying any Terraform code.

**HashiCorp Registry** (`terraform` server) — only these tools are relevant:

| Tool | When to use |
|------|-------------|
| `search_providers` | Find `oracle/oci` resource, data source, or guide docs |
| `get_provider_details` | Read full provider documentation for a specific resource |
| `get_latest_provider_version` | Check latest `oracle/oci` version; keep all 3 modules in sync |
| `search_modules` | Discover community modules (e.g. oci-compute-instance alternatives) |
| `get_module_details` | Read inputs, outputs, examples for a module before referencing it |
| `get_latest_module_version` | Verify the instances remote module has a newer tagged release |
| `search_policies` | Find Sentinel policies — useful if Checkov flags are too vague |
| `get_policy_details` | Read full policy docs |

Resources also available: `/terraform/style-guide` (fmt/naming) and
`/terraform/module-development` (module structure best practices).

**Terraform Best Practices** (`terraform-best-practices` server):
- `searchDocumentation` / `getPage` → code style, structure conventions
- The [code-styling](https://www.terraform-best-practices.com/code-styling) page
  recommends pre-commit-terraform hooks (see Required Workflow below)

Also use **OCI API tools** (`oci-identity`, `oci-networking`, `oci-compute`) to
validate OCIDs, compartments, subnets, images, and existing resources against
real state.

HCP Terraform workspace/run/variable tools are **not relevant** — this repo
uses local state per root module.

## Project Structure

Three independent Terraform root modules — each has its own state:

| Module | Path | Purpose |
|--------|------|---------|
| VCN | `terraform/vcn/` | VCN, subnets, routing, security lists |
| Instances | `terraform/instances/` | Compute (A1.Flex), uses remote module |
| Budget | `terraform/budget/` | Cost alerts (email) |

Each module has its own `providers.tf`, `variables.tf`, and `.terraform.lock.hcl`.
Run commands per-module with `terraform -chdir=terraform/<module>`.

## Git Rules

- **Never force push.** Add new commits only. `git push --force` and `--force-with-lease` are forbidden on any branch. If a PR review requires changes, make a new commit and push normally.

## Required Workflow

### Pre-commit hooks (required)

Repo includes a `.pre-commit-config.yaml` — install hooks with `pre-commit install`
so every commit runs formatting and validation automatically.
Follows [Terraform Best Practices](https://www.terraform-best-practices.com/code-styling)
recommendations.

Hooks: `terraform_fmt`, `terraform_validate`.

Module docs are auto-generated on merge to `main` via
`.github/workflows/terraform-docs.yml`. The workflow:
1. Runs `terraform-docs/gh-actions` with `find-dir` to generate per-module READMEs
2. Assembles each module's docs into the root `README.md` between `<!-- BEGIN_TF_DOCS <module> -->` / `<!-- END_TF_DOCS <module> -->` markers
3. Deletes per-module READMEs and commits the root `README.md` change only

Each module has a `.terraform-docs.yml` configuring sections: header,
requirements, inputs, outputs, resources, footer.

### Before creating a PR (for CI and uncommitted checks)

1. `terraform fmt -check -recursive terraform/`
2. `terraform -chdir=terraform/vcn init -backend=false && terraform -chdir=terraform/vcn validate`
3. Repeat step 2 for `instances` and `budget`

**Do not push code that hasn't passed fmt + validate.** Fix errors before
creating a PR.

## CI/CD

- `.github/workflows/lint.yml` — runs on PR to `main`: fmt, validate
- `.github/workflows/terraform-scan.yml` — Checkov scan on push/PR to main + weekly
- `.github/workflows/terraform-docs.yml` — generates module docs on push to `main`, assembles into root `README.md`
- `.github/dependabot.yml` — weekly terraform + GitHub Actions updates
- `.github/CODEOWNERS` — `* @rzkw`, all PRs need review

## Known Issues (actively being worked on)

- **Provider version drift**: `vcn` and `budget` pin `oracle/oci ~> 8.20.0`,
  `instances` pins `~> 8.2.0`. Being unified.
- **Remote module pinning**: Instances module uses git commit hash
  (`b19dbe0`) instead of a semver tag. Being migrated.

## Notes

- **No `.tfvars` committed** (gitignored). Values come from environment or CI.
- **VCN access**: SSH + Tailscale (UDP 41641) from home IP only.
- Wiki docs in `wiki/` cover architecture, security, IAM, and cost.

## Commit signing

All commits must be signed with SSH key `~/.ssh/agent-gh-signing`. [PERSON_NAME] is configured globally (`gpg.format = ssh`, `user.signingkey = ~/.ssh/agent-gh-signing.pub`, `commit.gpgsign = true`). Verify with `git log --show-signature -1` before pushing.
