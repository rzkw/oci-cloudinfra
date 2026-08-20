# Merge Bastion into VCN Module

Date: 2026-08-20

Status: AWAITING ADMIN APPROVAL

Depends on: PR #67 (bastion module), PR #65 (NAT gateway), PRs #59, #60 (Phase A state fixes)

## Problem

`terraform/vcn/main.tf:43` references `oci_bastion_bastion.bastion.private_endpoint_ip_address`, but that resource lives in a separate root module (`terraform/bastion/`). Terraform root modules have independent state files — cross-module resource references are not possible.

Additionally, `terraform/bastion/providers.tf:8` has `key = "terraform/vcn/terraform.tfstate"` — pointing at VCN's state key, not its own. A `terraform apply` in bastion would silently overwrite VCN state.

## Approach

Merge bastion resources into the VCN root module and delete the bastion directory. One root module → one state → direct resource references work.

## Steps

### 1. Add bastion resources to `terraform/vcn/main.tf`

Append after the existing `oci_core_subnet.dev` resource:

```hcl
resource "oci_bastion_bastion" "bastion" {
  bastion_type     = "STANDARD"
  compartment_id   = var.compartment_ocid
  target_subnet_id = oci_core_subnet.dev.id
  name             = "dev-bastion"

  client_cidr_block_allow_list = var.client_cidr_block_allow_list
  max_session_ttl_in_seconds   = 36000
}

resource "oci_bastion_session" "managed_ssh" {
  bastion_id   = oci_bastion_bastion.bastion
  display_name = "admin-ssh-session"

  key_details {
    public_key_content = var.bastion_public_key
  }

  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id                         = var.target_resource_id
    target_resource_operating_system_user_name = "ubuntu"
    target_resource_port                       = 22
  }
}
```

### 2. Add variables to `terraform/vcn/variables.tf`

```hcl
variable "target_resource_id" {
  description = "OCID of the compute instance to connect to via bastion"
  type        = string
}

variable "bastion_public_key" {
  description = "Public SSH key content used by the managed SSH session"
  type        = string
}

variable "client_cidr_block_allow_list" {
  description = "CIDR blocks allowed to connect to the bastion"
  type        = string
  default     = "0.0.0.0/0"
}
```

### 3. Add output to `terraform/vcn/outputs.tf`

```hcl
output "bastion_private_endpoint_ip" {
  description = "Bastion private endpoint IP, used in security list rules"
  value       = oci_bastion_bastion.bastion.private_endpoint_ip_address
}
```

### 4. Delete `terraform/bastion/` directory

```bash
git rm -r terraform/bastion/
```

### 5. Remove `instance_ad_number` from `terraform/instances/`

Single AD in use. Remove the variable and use the first AD from the data source (fixes the number/string type bug):

```hcl
# variables.tf — delete variable "instance_ad_number"

# main.tf — replace
# availability_domain = var.instance_ad_number
# with
data "oci_identity_availability_domains" "ad" {
  compartment_id = var.compartment_ocid
}
availability_domain = data.oci_identity_availability_domains.ad.availability_domains[0].name
```

### 6. State migration (if bastion already deployed)

```bash
# Delete wrong state key (bastion was pointed at VCN's key)
oci os object delete --bucket-name tfstate --namespace axvczntoncvg --name terraform/vcn/terraform.tfstate --force

# Re-init VCN
terraform -chdir=terraform/vcn init -upgrade

# Import existing bastion resources
terraform -chdir=terraform/vcn import oci_bastion_bastion.bastion <bastion-ocid>
terraform -chdir=terraform/vcn import oci_bastion_session.managed_ssh <session-ocid>
```

If bastion was never deployed, skip import.

## Verification

### Lint

```bash
terraform fmt -check -recursive terraform/
```

### Validate

```bash
terraform -chdir=terraform/vcn init -backend=false && terraform -chdir=terraform/vcn validate
terraform -chdir=terraform/instances init -backend=false && terraform -chdir=terraform/instances validate
```

### Plan (dry-run)

```bash
terraform -chdir=terraform/vcn plan
```

Expected: 2 new resources to add (`oci_bastion_bastion.bastion`, `oci_bastion_session.managed_ssh`), 0 to change, 0 to destroy (if bastion was never deployed).

### CI checks

- `lint.yml` — add `terraform-plan` job that runs `terraform init && terraform plan` for `vcn` and `instances` using OCI API credentials from GitHub secrets (`OCI_TENANCY_OCID`, `OCI_USER_OCID`, `OCI_FINGERPRINT`, `OCI_PRIVATE_KEY`, `OCI_REGION`). Requires CI user with read access to state bucket + VCN compartment. Fails the PR if plan exits non-zero or plans destroy of unremoved resources.
- `terraform-scan.yml` Checkov scan on all of `terraform/` — no new violations
- `terraform-docs.yml` auto-generates README — verify bastion resources appear in VCN docs

### Before deployment (budget check, per AGENTS.md)

Before `terraform apply` in `vcn`:

1. `pricing_search_name("Compute", "USD", require_priced=True)` — estimate bastion + instance cost
2. Compare against the $1/month budget in `terraform/budget/`
3. Only proceed if estimated costs are within budget

## Dropped

- `managed_ssh_command` output from bastion — referenced `oci_core_instance.this.private_ip` which doesn't exist in VCN scope. Was already broken. Can be added to instances module later if needed.

## References

- Terraform resource syntax (cross-module limitations): https://developer.hashicorp.com/terraform/language/resources/syntax
- OCI Bastion Service Terraform: https://blog.victorsilva.com.uy/oci-bastion-service-terraform/
- OCI Bastion managed SSH session: https://foggykitchen.com/2021/06/18/oci-bastion-service-terraform/
- Terraform Best Practices — key concepts: https://www.terraform-best-practices.com/key-concepts
- OCI backend config: https://developer.hashicorp.com/terraform/language/backend/oci
