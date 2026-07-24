# Getting Started

## Prerequisites

- Oracle Cloud account (Pay As You Go)
- Terraform >= 1.x installed locally
- OCI CLI configured (`oci setup config` — look for `DEFAULT` profile)
- SSH key pair
- Access to IP allowlisted in the security list

## 1. Clone and Configure

~~~bash
git clone git@github.com:rzkw/oci-cloudinfra.git
cd oci-cloudinfra
~~~

Set required variables. The VCN module needs your compartment OCID:

~~~bash
export TF_VAR_compartment_ocid="ocid1.compartment.oc1..aaaaaaaa..."
~~~

Other optional variables (instance shape, SSH keys, Tailscale auth key) — check `terraform/*/variables.tf` for the full list.

## 2. Deploy

Modules are independent. Deploy in order:

~~~bash
# Network first
cd terraform/vcn
terraform init && terraform apply
cd ../instances

# Compute (needs the subnet OCID from VCN output)
terraform init && terraform apply
cd ../budget

# Budget alerts
terraform init && terraform apply
cd ../..
~~~

## 3. Connect

**Via Bastion (recommended):**

1. Create a bastion session in the OCI console, or use the Terraform-managed session.
2. Copy the SSH command from the session details.
3. Replace `<privateKey>` with your key path and run it.

**Via Tailscale:**

If Tailscale is configured on the instance, connect through your tailnet directly — no bastion needed.

## 4. Ansible

The instance runs a cloud-init script on first boot that installs Ansible and pulls the playbook from `rzkw/ansible`. To re-run manually:

~~~bash
ssh <instance>  # via bastion or tailscale
ansible-playbook playbooks/server.yml
~~~

## Budget

The budget module sets a $1/month alert. You'll get email notifications when actual or forecasted spend hits 1% of the budget. To change the threshold, edit `terraform/budget/main.tf`.
