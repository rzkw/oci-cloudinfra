# IAM & Access Control

## Identity Domains

| Domain | Purpose | Users |
|--------|---------|-------|
| Default | Root access, billing, emergencies | Root user (FIDO2) |
| Operational | Day-to-day work | Admin user (MFA) |

The root user has full tenancy access by policy — can't be restricted. That's why it's locked down to emergency use only.

## Compartments

- **Root compartment** — created with the tenancy. Holds billing and tenancy-level resources.
- **Operational compartment** — all workloads live here. VMs, VCNs, budgets.

Keeping resources in the operational compartment means the admin user can manage them without having access to tenancy-level settings.

## Policies

Cross-domain policy (at tenancy root level):

~~~
Allow group 'Operational'/'Administrators' to manage all-resources in compartment <operational>
Allow group 'Operational'/'Administrators' to manage policies in compartment <operational>
Allow group 'Operational'/'Administrators' to inspect compartments in tenancy
~~~

Root restriction:

~~~
Allow group 'Default'/'Administrators' to manage all-resources in compartment <root-only>
~~~

This keeps the default domain admin out of the operational compartment.

## Agent Identity

A dedicated `agents` IAM user handles automation — AI coding assistants, CI, and any tooling that inspects infrastructure without a human at the keyboard. It's a separate user from the admin account, scoped to read-only.

**Permissions (read-only):**

~~~
Allow group <agents-group> to inspect all-resources in compartment <operational>
Allow group <agents-group> to read instances in compartment <operational>
Allow group <agents-group> to read virtual-network-family in compartment <operational>
~~~

The agent can list instances, inspect VCNs, read metadata. It can't create, modify, or delete anything.

**Use cases:**
- AI assistants inspecting live OCI state during development
- CI/CD pipelines checking instance state before deployment
- Ansible inventory discovery
- Monitoring scripts reading metrics and status

Auth uses API key (config file profile), not session tokens.

## Access Model Summary

| Identity | Daily Use | Scope | MFA |
|----------|-----------|-------|-----|
| Root user | No — emergencies only | Full tenancy | FIDO2 |
| Admin user | Yes | Operational compartment | MFA |
| Agent (`agents`) | Automated | Read-only | API key |

> **Note:** Update the group and policy names above to match your actual OCI configuration. The Terraform code doesn't manage IAM — these are set up manually in the console.
