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

**OCI Pricing MCP Server** (`uvx oracle.oci-pricing-mcp-server`):

| Tool | When to use |
|------|-------------|
| `pricing_search_name` | Check pricing for OCI services before deployment (e.g., "Compute pricing in USD") |
| `pricing_get_sku` | Look up specific SKU pricing |
| `ping` | Health check |

HCP Terraform workspace/run/variable tools are **not relevant** — this repo
uses local state per root module.

## Project Structure

Three independent Terraform root modules — each has its own state:

| Module | Path | Purpose |
|--------|------|---------|
| VCN | `terraform/vcn/` | VCN, subnets, routing, security lists |
| Instances | `terraform/instances/` | Compute (A1.Flex), cloud-init, block volumes |
| Budget | `terraform/budget/` | Cost alerts (email) |

Each module has its own `providers.tf`, `variables.tf`, and `.terraform.lock.hcl`.
Each root module's `backend "oci"` block must set a distinct `key`
(`terraform/<module>/terraform.tfstate`); a missing key defaults to
`terraform.tfstate` and silently collides with other modules.
Run commands per-module with `terraform -chdir=terraform/<module>`.

## Git Rules

- **Never force push.** Add new commits only. `git push --force` is forbidden on any branch. Use `--force-with-lease` when necessary. If a PR review requires changes, make a new commit and push normally.
- **Auto-assign reviewer.** Every PR must have `rzkw` assigned as reviewer. GitHub CODEOWNERS (`* @rzkw`) requests this review automatically — never remove or override it.

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

### Plan approval & references

- **No implementation without a merged plan.** Every non-trivial change
  (feature, refactor, infrastructure) requires a plan in `plans/` that has
  been committed and merged via PR before any code changes begin. Plans must
  be approved by the repo admin/code owner before implementation starts.
- All plans and reports MUST include a **References** section citing sources
  for every design decision (libraries, services, runtime behavior, security
  controls). Acceptable sources: official product documentation, personal blogs
  from engineers/devs/sysadmins, and product engineering blogs. Academic papers
  are never acceptable.
- All plans and reports MUST stay under 500 words, **including** the References
  section. This applies to all future documents only; existing plans/reports are
  exempt.
- Plans are saved under `plans/` with a dated filename.
- Reports (after completion, during WIP, etc.) are saved under `reports/` and
  reference the plan, PR, and commits.

### Before deployment (budget check)

Before applying any Terraform module, check pricing against the budget:

1. Use `pricing_search_name("Compute", "USD", require_priced=True)` to estimate new resource costs
2. Compare estimated costs against the $1/month budget in `terraform/budget/`
3. Only proceed if estimated costs are within budget

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
- Docs in `docs/` cover architecture, security, IAM, and cost.

## Commit signing

All commits must be signed with SSH key `~/.ssh/agent-gh-signing`. [PERSON_NAME] is configured globally (`gpg.format = ssh`, `user.signingkey = ~/.ssh/agent-gh-signing.pub`, `commit.gpgsign = true`). Verify with `git log --show-signature -1` before pushing.
