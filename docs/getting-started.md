# Getting Started

## Prerequisites

- Oracle Cloud account (Pay As You Go)
- Terraform >= 1.x installed locally
- OCI CLI configured (`oci setup config` — look for `DEFAULT` profile)
- SSH key pair
- Access to the tailnet and OCI Bastion IAM policy

## 1. Clone and Configure

~~~bash
git clone git@github.com:rzkw/oci-cloudinfra.git
cd oci-cloudinfra
~~~

Set required variables. The VCN module needs your compartment OCID:

~~~bash
export TF_VAR_compartment_ocid="ocid1.compartment.oc1..aaaaaaaa..."
~~~

For the instance, provide `ssh_public_keys`, `agent_ssh_public_key`, and `tailscale_auth_key`; check the module variables for all options.

## 2. Deploy

Modules are independent. Deploy in order:

~~~bash
# Network first
terraform -chdir=terraform/oci/vcn init && terraform -chdir=terraform/oci/vcn apply

# Compute (needs the subnet OCID from VCN output)
terraform -chdir=terraform/oci/instances init && terraform -chdir=terraform/oci/instances apply

# Budget alerts
terraform -chdir=terraform/oci/budget init && terraform -chdir=terraform/oci/budget apply
~~~

## 3. Connect

**Via Bastion:**

1. Create a bastion session in the OCI console, or use the Terraform-managed session.
2. Copy the SSH command from the session details.
3. Replace `<privateKey>` with your key path and run it.

**Via Tailscale (primary):**

After cloud-init has completed the Ansible `server.yml` playbook, connect over the tailnet using SSH keys. Verify direct connectivity after deployment with `tailscale ping home` and `tailscale status`.

**Via OCI Bastion (backup):**

Use the Terraform-managed SSH session as `ubuntu`. Instance TCP/22 is restricted to the dev subnet and is not open to the public internet.

## 4. Ansible

The instance runs cloud-init on first boot, installs the Ansible collections, and pulls `playbooks/server.yml` from `rzkw/ansible`. To re-run manually after connecting:

~~~bash
ssh <instance>  # via Bastion or Tailscale
sudo ansible-galaxy collection install -r /opt/ansible/collections/requirements.yml
sudo ansible-pull --url https://github.com/rzkw/ansible.git --directory /opt/ansible --inventory /opt/ansible/hosts.ini --tags level1-server,patch,setup_audit,run_audit playbooks/server.yml
~~~

## Budget

The budget module sets a $1/month alert. You'll get email notifications when actual or forecasted spend hits 1% of the budget. To change the threshold, edit `terraform/budget/main.tf`.
