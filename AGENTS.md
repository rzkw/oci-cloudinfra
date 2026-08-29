# AGENTS.md — rzkw/oci-cloudinfra

This repo holds Terraform code for a small Oracle Cloud (OCI) setup. It builds a
VCN, compute instances, a bastion host, and budget alerts. Each part is a
separate Terraform module.

## MCP Tool Usage

Before you write or change any Terraform, use the Terraform MCP servers.

**HashiCorp Registry** (`terraform` server) — use these tools:

| Tool | When to use |
|------|-------------|
| `search_providers` | Look up `oracle/oci` resource, data source, or guide docs |
| `get_provider_details` | Read the full docs for one resource |
| `get_latest_provider_version` | Check the latest `oracle/oci` version; keep all 4 modules in sync |
| `search_modules` | Find community modules (for example, oci-compute-instance) |
| `get_module_details` | Read a module's inputs, outputs, and examples before you use it |
| `get_latest_module_version` | Check if the instances module has a newer release |
| `search_policies` | Find Sentinel policies when Checkov flags are unclear |
| `get_policy_details` | Read the full policy docs |

You can also read `/terraform/style-guide` (format and naming) and
`/terraform/module-development` (module structure).

**Terraform Best Practices** (`terraform-best-practices` server):
- `searchDocumentation` / `getPage` — code style and structure
- The [code-styling](https://www.terraform-best-practices.com/code-styling) page
  shows formatting and validation rules

**OCI servers** (`oci-identity`, `oci-networking`, `oci-compute`,
`oci-pricing`): check real OCIDs, compartments, subnets, images, and resources.
Use `pricing_search_name`, `pricing_get_sku`, and `ping` to estimate cost before
you deploy (prices are in AUD by default).

Do not use the HCP Terraform tools (workspaces, runs, variables). This repo
keeps state in each module, not in HCP Terraform.

## Project Structure

The repo has four separate Terraform modules. Each keeps its own state:

| Module | Path | Purpose |
|--------|------|---------|
| VCN | `terraform/vcn/` | VCN, subnets, routing, security lists |
| Instances | `terraform/instances/` | Compute (A1.Flex), cloud-init |
| Bastion | `terraform/bastion/` | Jump host for private access |
| Budget | `terraform/budget/` | Cost alerts (email) |

Each module has its own `providers.tf`, `variables.tf`, and
`.terraform.lock.hcl`. Each `backend "oci"` block must use a different `key`
(`terraform/<module>/terraform.tfstate`). If you skip the `key`, it defaults to
`terraform.tfstate` and clashes with the other modules. Run commands per module
with `terraform -chdir=terraform/<module>`.

## Git Rules

- **Never force push.** Only add new commits. `git push --force` is forbidden.
  If you must, use `--force-with-lease`. When a PR review asks for changes, add
  a new commit and push it normally.
- **Auto-assign reviewer.** Every PR must list `rzkw` as reviewer. CODEOWNERS
  (`* @rzkw`) does this for you — never remove it.

## Required Workflow

### Module documentation

On merge to `main`, `.github/workflows/terraform-docs.yml` builds the docs:
1. Runs `terraform-docs/gh-actions` with `find-dir` to make a README per module
2. Joins each module's docs into the root `README.md` between
   `<!-- BEGIN_TF_DOCS <module> -->` and `<!-- END_TF_DOCS <module> -->`
3. Deletes the per-module READMEs and commits only the root `README.md` change

Each module has a `.terraform-docs.yml` that sets the doc sections: header,
requirements, inputs, outputs, resources, footer.

### Plan approval and references

- **Write a plan before you build.** Any non-trivial change (feature, refactor,
  or infrastructure) needs a plan in `plans/`. Commit it and merge it via PR
  before you change code. The repo owner must approve the plan first.
- **Add references.** Every plan and report must have a **References** section.
  List the source for each decision (library, service, runtime behavior,
  security control). Use official docs, engineering blogs, or sysadmin blogs.
  Do not use academic papers.
- **Keep it short.** Plans and reports must stay under 500 words, references
  included. This rule applies to new documents only; old ones are exempt.
- **Where to save.** Put plans in `plans/` with a dated name. Put reports in
  `reports/` and link the plan, PR, and commits.

### Check budget before deploy

Before you apply any module, check the cost against the budget. Cost only the
resources in this repo: vcn, instances, bastion, budget.

1. Estimate cost per resource with `pricing_search_name(...)` (AUD by default
   via `OCI_PRICING_DEFAULT_CCY`)
2. Compare it to the **live** budget. Read it from the read-only OCI account
   (`oci budgets budget budget list --compartment-id <tenancy_ocid> --all`) or
   the Budgets API — not from the local `terraform/budget/` config
3. Only continue if the cost fits the budget

If the pricing MCP server is down, get list prices from the public Price List
API:
https://apexapps.oracle.com/pls/apex/cetools/api/v1/products/

### Verify budget in plans and reports

When you write a plan or report, check the live budget against your changes:

1. Estimate the new cost with `pricing_search_name(...)` (public API, no login)
2. Read the live budget:
   `oci budgets budget budget list --compartment-id <tenancy_ocid> --all`
   (read-only)
3. Show both numbers — estimated cost and live budget — in the doc. Do not
   proceed if the cost exceeds the remaining budget

### Before you open a PR

1. `terraform fmt -check -recursive terraform/`
2. `terraform -chdir=terraform/vcn init -backend=false && terraform -chdir=terraform/vcn validate`
3. Run step 2 for `instances`, `bastion`, and `budget`

Do not push code that fails fmt or validate. Fix the errors first.

## CI/CD

- `.github/workflows/lint.yml` — on PR to `main`: fmt and validate
- `.github/workflows/terraform-scan.yml` — Checkov scan on push/PR to `main`,
  plus weekly
- `.github/workflows/terraform-docs.yml` — on push to `main`: builds module
  docs into root `README.md`
- `.github/dependabot.yml` — weekly updates for Terraform and GitHub Actions
- `.github/CODEOWNERS` — `* @rzkw`, so every PR needs review

## Notes

- **No `.tfvars` committed.** They are gitignored. Values come from the
  environment or CI.
- **VCN access:** SSH and Tailscale (UDP 41641) from the home IP only.
- The `docs/` folder covers architecture, security, IAM, and cost.

## Commit signing

Sign every commit with the SSH key `~/.ssh/agent-gh-signing`. Signing is set
globally (`gpg.format = ssh`, `user.signingkey = ~/.ssh/agent-gh-signing.pub`,
`commit.gpgsign = true`). Before you push, check with
`git log --show-signature -1`.
