# Report: Merge Bastion into VCN — Steps 1–3

Date: 2026-08-20

Plan: `plans/2026-08-20-merge-bastion-into-vcn.md` (approved via PR #72,
merged 2026-08-20)

PR: #72 (plan), this PR (implementation)

## Completed (plan steps 1–3)

### Step 1 — bastion resources in `terraform/vcn/main.tf`

- Added `oci_bastion_bastion.bastion` (`STANDARD`, subnet = `oci_core_subnet.dev`).
- Added `oci_bastion_session.managed_ssh` using `var.bastion_public_key`.
- **Deviation from plan:** `bastion_id = oci_bastion_bastion.bastion.id` (the
  plan's `bastion_id = oci_bastion_bastion.bastion` fails validate — attribute
  expects a string, not the resource object).
- **Cycle resolution:** the security-list SSH-from-bastion rule now uses a
  `dynamic "ingress_security_rules"` gated on `var.bastion_private_ip` instead
  of a direct reference to `oci_bastion_bastion.bastion.private_endpoint_ip_address`.
  The direct reference creates a Terraform cycle
  (`bastion → subnet → security_list → bastion`); a single apply cannot resolve
  it. This also preserves the deploy-VCN-first flow: set `bastion_private_ip`
  after the bastion apply to add the SSH rule.

### Step 2 — variables in `terraform/vcn/variables.tf`

- Added `target_resource_id`, `bastion_public_key`,
  `client_cidr_block_allow_list`, and `bastion_private_ip`.
- **Deviation from plan:** `client_cidr_block_allow_list` is `list(string)`
  (plan had `string`) — the `oci_bastion_bastion` attribute requires a list.

### Step 3 — output in `terraform/vcn/outputs.tf`

- Added `bastion_private_endpoint_ip` output.

## Verified

- `terraform fmt -recursive terraform/vcn/` — clean.
- `terraform -chdir=terraform/vcn init -backend=false && terraform -chdir=terraform/vcn validate` — success.

## Not executed (out of scope for this PR)

- Step 4 — delete `terraform/bastion/` directory.
- Step 5 — remove `instance_ad_number` from `terraform/instances/`.
- Step 6 — state migration / imports.
- `terraform plan` CI job and budget-check pricing run (plan review points 3–4).

These require a follow-up PR; the merged plan covers all of them.

## References

- Plan: `plans/2026-08-20-merge-bastion-into-vcn.md`
- Terraform `dynamic` blocks: https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks
- OCI Bastion Service Terraform (blog): https://blog.victorsilva.com.uy/oci-bastion-service-terraform/
- OCI Bastion managed SSH session (blog): https://foggykitchen.com/2021/06/18/oci-bastion-service-terraform/
