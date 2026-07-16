# OCI Bucket Remote State + Resource Import Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the 3 Terraform root modules (`vcn`, `instances`, `budget`) from local state to the OCI Object Storage backend, then use config-driven import to bring existing deployed resources into state.

**Architecture:** Each module gets a `backend "oci"` block pointing to a shared Object Storage bucket (`tfstate-oci-cloudinfra`) with per-module state keys. Existing resources are imported using Terraform 1.5+ `import` blocks and `-generate-config-out` to produce config from live infrastructure, then pruned to match existing code. Credentials are provided via OCI environment variables — never hardcoded in backend blocks.

**Tech Stack:** Terraform >= 1.5, oracle/oci ~> 8.20, OCI CLI v3.88.0, OCI Object Storage

## Global Constraints

- Terraform >= 1.5 (config-driven import requires 1.5+)
- oracle/oci provider pinned at `~> 8.20` (all 3 modules must stay in sync)
- OCI auth via env vars (`OCI_TENANCY_OCID`, `OCI_USER_OCID`, `OCI_FINGERPRINT`, `OCI_PRIVATE_KEY`, `OCI_REGION`) or `~/.oci/config` profile
- Region: `ap-melbourne-1`
- Never commit `.tfstate`, `.tfvars`, `.pem`, or `.env` files (already gitignored)
- Never hardcode secrets or OCIDs in backend blocks — use env vars for credentials
- Enable bucket versioning for state recovery (per HashiCorp recommendation)
- Run `terraform fmt -check -recursive` and `terraform validate` before any PR

---

## File Structure

| File | Action | Purpose |
|------|--------|---------|
| `terraform/vcn/main.tf` | Modify | Add `backend "oci"` block inside existing `terraform {}` |
| `terraform/instances/providers.tf` | Modify | Add `backend "oci"` block inside existing `terraform {}` |
| `terraform/budget/providers.tf` | Modify | Add `backend "oci"` block inside existing `terraform {}` |
| `terraform/vcn/import.tf` | Create (temporary) | Import blocks for VCN, IGW, RT, SL, Subnet |
| `terraform/vcn/generated.tf` | Create (temporary) | Generated config from `-generate-config-out` |
| `terraform/instances/import.tf` | Create (temporary) | Import block for instance via remote module path |
| `terraform/instances/generated.tf` | Create (temporary) | Generated config from `-generate-config-out` |
| `terraform/budget/import.tf` | Create (temporary) | Import blocks for budget + alert rules |
| `terraform/budget/generated.tf` | Create (temporary) | Generated config from `-generate-config-out` |

---

## Task 1: Bootstrap OCI Object Storage Bucket

**Files:**
- None created (bucket is created via OCI CLI, outside Terraform)

**Interfaces:**
- Consumes: OCI CLI auth (`~/.oci/config` or env vars)
- Produces: Bucket `tfstate-oci-cloudinfra` in root compartment; `$OCI_NS` namespace value

- [ ] **Step 1: Verify OCI CLI is installed and authenticated**

Run: `oci --version`
Expected: `3.88.0` or similar

Run: `oci iam compartment list --include-root --query 'data[0].id' -r`
Expected: returns root tenancy OCID (e.g., `ocid1.tenancy.oc1..aaaa...`)

- [ ] **Step 2: Get compartment OCID for bucket placement**

```bash
ROOT_TENANCY_OCID=$(oci iam compartment list --include-root --query 'data[0].id' -r)
echo "Root tenancy OCID: $ROOT_TENANCY_OCID"
```

- [ ] **Step 3: Create the state bucket**

```bash
oci os bucket create \
  --name tfstate-oci-cloudinfra \
  --compartment-id "$ROOT_TENANCY_OCID" \
  --versioning ENABLED
```

Expected output: JSON with bucket details including `name: "tfstate-oci-cloudinfra"`

- [ ] **Step 4: Retrieve namespace**

```bash
OCI_NS=$(oci os ns get --query data -r)
echo "Namespace: $OCI_NS"
```

Save this value — it goes in every backend block.

- [ ] **Step 5: Verify bucket exists**

Run: `oci os object list --bucket-name tfstate-oci-cloudinfra --namespace "$OCI_NS" --query 'data[].name'`
Expected: empty list `[]` (fresh bucket)

---

## Task 2: Add OCI Backend to VCN Module

**Files:**
- Modify: `terraform/vcn/main.tf:1-8`

**Interfaces:**
- Consumes: `$OCI_NS` from Task 1
- Produces: Backend configured at `vcn/terraform.tfstate` in bucket

- [ ] **Step 1: Add backend block to `terraform/vcn/main.tf`**

Replace the existing `terraform {}` block (lines 1-8) with:

```hcl
terraform {
  backend "oci" {
    bucket    = "tfstate-oci-cloudinfra"
    namespace = "<YOUR_NAMESPACE>"
    key       = "vcn/terraform.tfstate"
  }

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.20"
    }
  }
}
```

Replace `<YOUR_NAMESPACE>` with the value from Task 1 Step 4.

- [ ] **Step 2: Verify formatting**

Run: `terraform -chdir=terraform/vcn fmt -check`
Expected: no output (all files formatted)

- [ ] **Step 3: Run init with backend migration**

Run: `terraform -chdir=terraform/vcn init`
Expected output includes:

```
Successfully configured the backend "oci"!
Terraform has been successfully initialized!
```

Since this is a fresh backend with no prior state, Terraform will not prompt for migration.

- [ ] **Step 4: Verify backend is configured**

Run: `terraform -chdir=terraform/vcn show`
Expected: `No resources. This is empty.` (local state is empty, now using OCI backend)

---

## Task 3: Add OCI Backend to Instances Module

**Files:**
- Modify: `terraform/instances/providers.tf:1-8`

**Interfaces:**
- Consumes: `$OCI_NS` from Task 1
- Produces: Backend configured at `instances/terraform.tfstate` in bucket

- [ ] **Step 1: Add backend block to `terraform/instances/providers.tf`**

Replace the existing `terraform {}` block (lines 1-8) with:

```hcl
terraform {
  backend "oci" {
    bucket    = "tfstate-oci-cloudinfra"
    namespace = "<YOUR_NAMESPACE>"
    key       = "instances/terraform.tfstate"
  }

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.20"
    }
  }
}
```

Replace `<YOUR_NAMESPACE>` with the value from Task 1 Step 4.

- [ ] **Step 2: Verify formatting**

Run: `terraform -chdir=terraform/instances fmt -check`
Expected: no output

- [ ] **Step 3: Run init**

Run: `terraform -chdir=terraform/instances init`
Expected: `Successfully configured the backend "oci"!`

- [ ] **Step 4: Verify backend**

Run: `terraform -chdir=terraform/instances show`
Expected: `No resources. This is empty.`

---

## Task 4: Add OCI Backend to Budget Module

**Files:**
- Modify: `terraform/budget/providers.tf:1-8`

**Interfaces:**
- Consumes: `$OCI_NS` from Task 1
- Produces: Backend configured at `budget/terraform.tfstate` in bucket

- [ ] **Step 1: Add backend block to `terraform/budget/providers.tf`**

Replace the existing `terraform {}` block (lines 1-8) with:

```hcl
terraform {
  backend "oci" {
    bucket    = "tfstate-oci-cloudinfra"
    namespace = "<YOUR_NAMESPACE>"
    key       = "budget/terraform.tfstate"
  }

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.20"
    }
  }
}
```

Replace `<YOUR_NAMESPACE>` with the value from Task 1 Step 4.

- [ ] **Step 2: Verify formatting**

Run: `terraform -chdir=terraform/budget fmt -check`
Expected: no output

- [ ] **Step 3: Run init**

Run: `terraform -chdir=terraform/budget init`
Expected: `Successfully configured the backend "oci"!`

- [ ] **Step 4: Verify backend**

Run: `terraform -chdir=terraform/budget show`
Expected: `No resources. This is empty.`

---

## Task 5: Look Up OCIDs of Deployed VCN Resources

**Files:**
- None created (OCI CLI lookups only)

**Interfaces:**
- Consumes: OCI CLI auth, compartment OCID
- Produces: Shell variables `$COMPARTMENT_OCID`, `$VCN_ID`, `$IGW_ID`, `$RT_ID`, `$SL_ID`, `$SUBNET_ID`

- [ ] **Step 1: Set compartment OCID**

```bash
COMPARTMENT_OCID="ocid1.compartment.oc1..<YOUR_COMPARTMENT>"
echo "Compartment: $COMPARTMENT_OCID"
```

Find this from OCI Console → Identity & Security → Compartments, or via:
```bash
oci iam compartment list --name "Comp-1" --query 'data[0].id' -r
```

- [ ] **Step 2: Look up VCN OCID**

```bash
VCN_ID=$(oci network vcn list \
  --compartment-id "$COMPARTMENT_OCID" \
  --display-name "My internal VCN" \
  --query 'data[0].id' -r)
echo "VCN: $VCN_ID"
```

- [ ] **Step 3: Look up Internet Gateway OCID**

```bash
IGW_ID=$(oci network internet-gateway list \
  --compartment-id "$COMPARTMENT_OCID" \
  --vcn-id "$VCN_ID" \
  --query 'data[0].id' -r)
echo "IGW: $IGW_ID"
```

- [ ] **Step 4: Look up Route Table OCID**

```bash
RT_ID=$(oci network route-table list \
  --compartment-id "$COMPARTMENT_OCID" \
  --vcn-id "$VCN_ID" \
  --display-name "Dev Route Table" \
  --query 'data[0].id' -r)
echo "RT: $RT_ID"
```

- [ ] **Step 5: Look up Security List OCID**

```bash
SL_ID=$(oci network security-list list \
  --compartment-id "$COMPARTMENT_OCID" \
  --vcn-id "$VCN_ID" \
  --display-name "Internal Security List" \
  --query 'data[0].id' -r)
echo "SL: $SL_ID"
```

- [ ] **Step 6: Look up Subnet OCID**

```bash
SUBNET_ID=$(oci network subnet list \
  --compartment-id "$COMPARTMENT_OCID" \
  --vcn-id "$VCN_ID" \
  --display-name "dev" \
  --query 'data[0].id' -r)
echo "Subnet: $SUBNET_ID"
```

- [ ] **Step 7: Verify all OCIDs are set**

```bash
echo "VCN:    $VCN_ID"
echo "IGW:    $IGW_ID"
echo "RT:     $RT_ID"
echo "SL:     $SL_ID"
echo "Subnet: $SUBNET_ID"
```

Each variable should start with `ocid1.` and not be empty.

---

## Task 6: Import VCN Resources via Config-Driven Import

**Files:**
- Create: `terraform/vcn/import.tf`
- Create: `terraform/vcn/generated.tf` (auto-generated, temporary)

**Interfaces:**
- Consumes: `$VCN_ID`, `$IGW_ID`, `$RT_ID`, `$SL_ID`, `$SUBNET_ID` from Task 5; backend from Task 2
- Produces: All 5 VCN resources imported into OCI-backed state; `terraform plan` shows no changes

- [ ] **Step 1: Create `terraform/vcn/import.tf` with import blocks**

Create file `terraform/vcn/import.tf` with the following content, replacing the OCID placeholders:

```hcl
import {
  id = "$VCN_ID"
  to = oci_core_vcn.internal
}

import {
  id = "$IGW_ID"
  to = oci_core_internet_gateway.internal
}

import {
  id = "$RT_ID"
  to = oci_core_route_table.dev
}

import {
  id = "$SL_ID"
  to = oci_core_security_list.internal
}

import {
  id = "$SUBNET_ID"
  to = oci_core_subnet.dev
}
```

Replace each `$VARIABLE` with the actual OCID value from Task 5.

- [ ] **Step 2: Run plan with config generation**

Run: `terraform -chdir=terraform/vcn plan -generate-config-out=generated.tf`

Expected output: Terraform will show an import plan for all 5 resources, and write `generated.tf`.

The plan should show:
```
Plan: 5 to import, 0 to add, 0 to change, 0 to destroy.
```

- [ ] **Step 3: Review `generated.tf` and compare with `main.tf`**

Read `terraform/vcn/generated.tf`. It will contain full resource definitions with all attributes (including defaults).

Compare each resource with the existing `main.tf`. For example, the generated VCN:

```hcl
resource "oci_core_vcn" "internal" {
  cidr_block                     = "172.16.0.0/20"
  compartment_id                 = "ocid1.compartment.oc1..aaaa..."
  display_name                   = "My internal VCN"
  dns_label                      = "internal"
  defined_tags                   = {}
  freeform_tags                  = {}
  is_ipv6enabled                 = false
  is_oracle_gua_allocation_enabled = false
}
```

Your existing `main.tf` already defines these resources correctly. The generated config is a reference — do not merge it. The existing `main.tf` is the source of truth.

- [ ] **Step 4: Apply the import**

Run: `terraform -chdir=terraform/vcn apply`

Type `yes` when prompted. Expected output:
```
Apply complete! Resources: 5 imported, 0 added, 0 changed, 0 destroyed.
```

- [ ] **Step 5: Verify no drift**

Run: `terraform -chdir=terraform/vcn plan`
Expected: `No changes. Your infrastructure matches your configuration.`

- [ ] **Step 6: Cleanup temporary files**

```bash
rm terraform/vcn/import.tf terraform/vcn/generated.tf
```

- [ ] **Step 7: Commit the backend change**

```bash
git add terraform/vcn/main.tf
git commit -S -m "feat(vcn): add OCI Object Storage backend for remote state"
```

---

## Task 7: Import Instance Resources via Config-Driven Import

**Files:**
- Create: `terraform/instances/import.tf`
- Create: `terraform/instances/generated.tf` (auto-generated, temporary)

**Interfaces:**
- Consumes: OCI CLI auth, compartment OCID; backend from Task 3
- Produces: Instance resource imported into OCI-backed state; `terraform plan` shows no changes

**Note:** The instance resource is `oci_core_instance.this[0]`.

- [ ] **Step 1: Look up instance OCID**

```bash
INSTANCE_ID=$(oci compute instance list \
  --compartment-id "$COMPARTMENT_OCID" \
  --lifecycle-state RUNNING \
  --query 'data[0].id' -r)
echo "Instance: $INSTANCE_ID"
```

If no running instance exists, check stopped instances:
```bash
INSTANCE_ID=$(oci compute instance list \
  --compartment-id "$COMPARTMENT_OCID" \
  --lifecycle-state STOPPED \
  --query 'data[0].id' -r)
echo "Instance: $INSTANCE_ID"
```

- [ ] **Step 2: Verify instance exists**

Run: `oci compute instance get --instance-id "$INSTANCE_ID" --query 'data.{name:display_name,state:lifecycle_state,shape:shape}'`
Expected: shows instance name, state, and shape (e.g., `VM.Standard.A1.Flex`)

- [ ] **Step 3: Create `terraform/instances/import.tf`**

Create file `terraform/instances/import.tf` with the import block. Replace `$INSTANCE_ID` with the actual OCID:

```hcl
import {
  id = "$INSTANCE_ID"
  to = oci_core_instance.this[0]
}
```

- [ ] **Step 4: Run plan with config generation**

Run: `terraform -chdir=terraform/instances plan -generate-config-out=generated.tf`

If the module doesn't expose the internal resource address for import, you will see an error. In that case, use a fallback approach: create a standalone `oci_core_instance` resource directly in `main.tf` instead of using the remote module for this instance.

Expected output (success case):
```
Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
```

- [ ] **Step 5: Review generated config**

Read `terraform/instances/generated.tf`. Compare with the existing `main.tf` module invocation. The generated config will show all attributes — prune to only required and non-default values.

Key attributes to verify match:
- `shape` = `VM.Standard.A1.Flex`
- `shape_config.ocpus` = `2`
- `shape_config.memory_in_gbs` = `12`
- `source_details.source_id` = the image OCID from `var.source_ocid`

- [ ] **Step 6: Apply the import**

Run: `terraform -chdir=terraform/instances apply`

Type `yes` when prompted. Expected output:
```
Apply complete! Resources: 1 imported, 0 added, 0 changed, 0 destroyed.
```

- [ ] **Step 7: Verify no drift**

Run: `terraform -chdir=terraform/instances plan`
Expected: `No changes. Your infrastructure matches your configuration.`

If there are changes, review and update `main.tf` or variables to match reality.

- [ ] **Step 8: Cleanup temporary files**

```bash
rm terraform/instances/import.tf terraform/instances/generated.tf
```

- [ ] **Step 9: Commit the backend change**

```bash
git add terraform/instances/providers.tf
git commit -S -m "feat(instances): add OCI Object Storage backend for remote state"
```

---

## Task 8: Import Budget Resources via Config-Driven Import

**Files:**
- Create: `terraform/budget/import.tf`
- Create: `terraform/budget/generated.tf` (auto-generated, temporary)

**Interfaces:**
- Consumes: OCI CLI auth, tenancy OCID; backend from Task 4
- Produces: Budget + 2 alert rules imported into OCI-backed state; `terraform plan` shows no changes

- [ ] **Step 1: Look up budget OCID**

```bash
BUDGET_ID=$(oci budget budget list \
  --compartment-id "$ROOT_TENANCY_OCID" \
  --display-name "Free" \
  --query 'data[0].id' -r)
echo "Budget: $BUDGET_ID"
```

- [ ] **Step 2: Look up alert rule OCIDs**

```bash
FORECAST_ALERT_ID=$(oci budget alert-rule list \
  --budget-id "$BUDGET_ID" \
  --query "data[?type=='FORECAST'].id | [0]" -r)
echo "Forecast alert: $FORECAST_ALERT_ID"

ACTUAL_ALERT_ID=$(oci budget alert-rule list \
  --budget-id "$BUDGET_ID" \
  --query "data[?type=='ACTUAL'].id | [0]" -r)
echo "Actual alert: $ACTUAL_ALERT_ID"
```

- [ ] **Step 3: Create `terraform/budget/import.tf`**

Create file `terraform/budget/import.tf` with the import blocks. Replace the OCID placeholders:

```hcl
import {
  id = "$BUDGET_ID"
  to = oci_budget_budget.dollar_budget
}

import {
  id = "$FORECAST_ALERT_ID"
  to = oci_budget_alert_rule.forecast
}

import {
  id = "$ACTUAL_ALERT_ID"
  to = oci_budget_alert_rule.actual
}
```

Replace each `$VARIABLE` with the actual OCID value.

- [ ] **Step 4: Run plan with config generation**

Run: `terraform -chdir=terraform/budget plan -generate-config-out=generated.tf`

Expected output:
```
Plan: 3 to import, 0 to add, 0 to change, 0 to destroy.
```

- [ ] **Step 5: Review generated config**

Read `terraform/budget/generated.tf`. Compare with existing `main.tf`.

Key attributes to verify:
- `oci_budget_budget.dollar_budget`: `amount = 1`, `reset_period = "MONTHLY"`, `target_type = "COMPARTMENT"`
- `oci_budget_alert_rule.forecast`: `type = "FORECAST"`, `threshold = 1`, `threshold_type = "PERCENTAGE"`
- `oci_budget_alert_rule.actual`: `type = "ACTUAL"`, `threshold = 1`, `threshold_type = "PERCENTAGE"`

- [ ] **Step 6: Apply the import**

Run: `terraform -chdir=terraform/budget apply`

Type `yes` when prompted. Expected output:
```
Apply complete! Resources: 3 imported, 0 added, 0 changed, 0 destroyed.
```

- [ ] **Step 7: Verify no drift**

Run: `terraform -chdir=terraform/budget plan`
Expected: `No changes. Your infrastructure matches your configuration.`

- [ ] **Step 8: Cleanup temporary files**

```bash
rm terraform/budget/import.tf terraform/budget/generated.tf
```

- [ ] **Step 9: Commit the backend change**

```bash
git add terraform/budget/providers.tf
git commit -S -m "feat(budget): add OCI Object Storage backend for remote state"
```

---

## Task 9: Post-Migration Verification

**Files:**
- None modified

**Interfaces:**
- Consumes: All backends configured; all resources imported
- Produces: Verified state in OCI; all modules show no changes

- [ ] **Step 1: Verify all modules show no changes**

```bash
terraform -chdir=terraform/vcn plan
terraform -chdir=terraform/instances plan
terraform -chdir=terraform/budget plan
```

All three should output: `No changes. Your infrastructure matches your configuration.`

- [ ] **Step 2: Verify state files exist in OCI**

```bash
OCI_NS=$(oci os ns get -r data)
oci os object list \
  --bucket-name tfstate-oci-cloudinfra \
  --namespace "$OCI_NS" \
  --query 'data[].name'
```

Expected output:
```
[
  "budget/terraform.tfstate",
  "instances/terraform.tfstate",
  "vcn/terraform.tfstate"
]
```

- [ ] **Step 3: Run fmt and validate across all modules**

```bash
terraform fmt -check -recursive terraform/
terraform -chdir=terraform/vcn validate
terraform -chdir=terraform/instances validate
terraform -chdir=terraform/budget validate
```

All should pass with no errors.

- [ ] **Step 4: Verify git status is clean**

Run: `git status`
Expected: working tree clean (all changes committed)

---

## Rollback Procedure

If something goes wrong at any point:

### Option A: Revert to local state

1. Remove the `backend "oci" {}` block from each module's `main.tf` (vcn) or `providers.tf` (instances, budget)
2. Run `terraform init -migrate-state` — this pulls state back from OCI to local
3. Delete the bucket if desired:

```bash
OCI_NS=$(oci os ns get -r data)
oci os object delete --bucket-name tfstate-oci-cloudinfra --object-name "vcn/terraform.tfstate" --force
oci os object delete --bucket-name tfstate-oci-cloudinfra --object-name "instances/terraform.tfstate" --force
oci os object delete --bucket-name tfstate-oci-cloudinfra --object-name "budget/terraform.tfstate" --force
oci os bucket delete --bucket-name tfstate-oci-cloudinfra --force
```

### Option B: Restore from bucket versioning

If a state file was accidentally corrupted or deleted, bucket versioning (enabled in Task 1) allows recovery of previous state versions via OCI Console or CLI.
