# IAM & Access Control

## Identity Domains

| Domain | Purpose | Users |
|--------|---------|-------|
| Default | Root access, billing, emergencies | Root user (`hello@walk-llc.com`) |
| `domain-dev` | Day-to-day operations | Admin user, `agents` user |

The root user (`Administrators` group in Default domain) has full tenancy access by policy — can't be restricted. Locked down to emergency use only.

## Compartments

| Compartment | OCID |
|-------------|------|
| Comp-1 | `ocid1.compartment.oc1..aaaaaaaau45ubk37...` |

Comp-1 holds all operational resources — VCN, instances, VNICs, budgets. The root compartment holds billing and tenancy-level resources only.

## Policies

All policies are at tenancy root level. Terraform doesn't manage IAM — these are set up manually in the console.

### `rizky-primary-admin` — admin access to Comp-1

~~~
Allow group 'domain-dev'/'Administrators' to manage all-resources in compartment Comp-1
Allow group 'domain-dev'/'Administrators' to manage policies in compartment Comp-1
Allow group 'domain-dev'/'Administrators' to manage compartments in tenancy
~~~

Grants the `domain-dev/Administrators` group full control over Comp-1 plus the ability to create compartments and manage policies.

### `read-only` — agent inspection

~~~
Allow group 'domain-dev'/'agents' to inspect all-resources in tenancy
Allow group 'agents' to inspect users in tenancy
Allow group 'agents' to inspect groups in tenancy
Allow group 'agents' to inspect policies in tenancy
~~~

The `agents` group can list and read any resource in the tenancy but can't create, modify, or delete anything. The first statement covers resources (compute, network, storage). The last three cover IAM metadata (users, groups, policies).

The `agents` user authenticates with an API key — the `[agents]` profile in `~/.oci/config`.

### `Bastion` — bastion service access

~~~
Allow group BastionUsers to use bastions in tenancy
Allow group BastionUsers to read instances in tenancy
Allow group BastionUsers to read vcn in tenancy
Allow group BastionUsers to manage bastion-session in tenancy
Allow group BastionUsers to read subnets in tenancy
Allow group BastionUsers to read instance-agent-plugins in tenancy
Allow group BastionUsers to read vnic-attachments in tenancy
Allow group BastionUsers to read vnics in tenancy
~~~

### `cloud-shell` — cloud shell access

~~~
Allow group 'domain-dev'/'Administrators' to use cloud-shell in tenancy
~~~

### `tfstate-bucket` — terraform state access

~~~
Allow any-user to manage buckets in compartment Comp-1
  where all {
    target.bucket.name='tfstate',
    request.user.id ='ocid1.user.oc1..aaaaaaa...'
  }
~~~

Scoped to the compute instance's OCID — only that instance can read and write the tfstate bucket.

### `Tenant Admin Policy` — default root access

~~~
ALLOW GROUP Administrators to manage all-resources IN TENANCY
~~~

OCI-created default. The `Administrators` group in the Default domain retains full tenancy access. This is why the root account is locked down.

## Authentication

| Identity | Console | API | Purpose |
|----------|---------|-----|---------|
| Root user | FIDO2 | API key | Emergency and billing only |
| Admin user (`domain-dev`) | MFA | API key | Daily operations |
| `agents` user | — | API key | Automated workflows |

## Use Cases

The `agents` identity is the primary automation path:
- AI coding assistants inspecting live OCI state
- CI/CD pipelines checking instance state before deployment
- Ansible inventory discovery
- Monitoring scripts reading metrics and status
