# Archived Setup Guide

> **This guide is archived.** The manual OCI console steps below are outdated and describe a different architecture (10.0.0.0/16 VCN with NAT Gateway). Current infrastructure is managed via Terraform — see [Getting Started](Getting-Started.md).

The original walkthrough covered: compartment creation, identity domain setup, cross-domain policies, VCN with public/private subnets, NAT Gateway, bastion service, and compute instance creation — all via the OCI console.

These steps were written for a demo/portfolio context and described a "defense-in-depth" architecture. The current setup is simpler: one private VCN, one instance, bastion access, Tailscale mesh. All Terraform-managed.

Kept for reference in case the manual steps are useful for other OCI projects.

---

## Original Guide (November 2025)

### Phase 1: Foundation Setup (As Root User)

#### Step 1: Create Your Operational Compartment

1. Login to OCI Console as root user → https://cloud.oracle.com
2. ☰ menu → Identity & Security → Compartments
3. Create Compartment:

| Field | Value |
|-------|-------|
| Name | Comp-1 |
| Description | Operational compartment for dev/test resources |
| Parent Compartment | (root) |

#### Step 2: Create Your Operational Identity Domain

1. ☰ menu → Identity & Security → Domains → Create Domain
2. Display name: `domain-dev`, Type: Free, Compartment: Comp-1
3. Check "Create an administrative user for this domain"
4. Wait for Active status (2-3 minutes)

#### Step 3: Create Cross-Domain Access Policy

1. ☰ menu → Identity & Security → Policies
2. Compartment dropdown: `<root>` (tenancy level)
3. Create Policy — Show manual editor, paste:

```
Allow group 'domain-dev'/'Administrators' to manage all-resources in compartment Comp-1
Allow group 'domain-dev'/'Administrators' to manage policies in compartment Comp-1
Allow group 'domain-dev'/'Administrators' to inspect compartments in tenancy
```

#### Step 4: Test Cross-Domain Access

Logout, login as domain-dev admin. Verify Comp-1 is visible, root compartment is not.

#### Step 5: Restrict Default Domain Access

Create policy: `Allow group 'Default'/'Administrators' to manage all-resources in compartment hello17`

### Phase 2: Network & Infrastructure Setup

#### Step 6: Create VCN

☰ → Networking → Virtual Cloud Networks → Create VCN
- Name: vcn-1, CIDR: 10.0.0.0/16, DNS hostnames enabled

#### Step 7: Create Subnets

- Public: 10.0.0.0/24, Public Subnet
- Private: 10.0.1.0/24, Private Subnet

#### Step 8: Security List — SSH (port 22) ingress from Bastion

#### Step 9: Create Compute Instance

VM.Standard.A1.Flex, 4 OCPU / 24GB, Ubuntu 22.04, 200GB boot volume

#### Step 10: NAT Gateway via Quick Actions

Connects private subnet to internet for outbound traffic.

#### Step 12: Bastion Service

Create bastion, enable Bastion plugin on instance, create managed SSH session.

---

*This content is preserved for reference. For current setup instructions, see [Getting Started](Getting-Started.md).*
