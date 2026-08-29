# Three-root-module pattern (network / compute / bastion) with remote state
# data sources. Reference:
# https://martincarstenbach.com/2021/11/12/create-an-oci-bastion-service-via-terraform/

data "terraform_remote_state" "vcn" {
  backend = "oci"
  config = {
    bucket    = "tfstate"
    namespace = "axvczntoncvg"
    key       = "terraform/vcn/terraform.tfstate"
    region    = var.region
  }
}

data "terraform_remote_state" "instances" {
  backend = "oci"
  config = {
    bucket    = "tfstate"
    namespace = "axvczntoncvg"
    key       = "terraform/instances/terraform.tfstate"
    region    = var.region
  }
}

# Bastion service in the same private subnet as the instance.
resource "oci_bastion_bastion" "bastion" {
  bastion_type     = "STANDARD"
  compartment_id   = var.compartment_ocid
  target_subnet_id = data.terraform_remote_state.vcn.outputs.dev_subnet_ocid
  name             = "dev-bastion"

  client_cidr_block_allow_list = var.client_cidr_block_allow_list
  max_session_ttl_in_seconds   = 36000
}

# Managed SSH session targeting the instance from instances module state.
# key_details.public_key_content is required; the session propagates this key
# to the target's authorized_keys for the OS user.
# Ref: https://docs.oracle.com/en-us/iaas/Content/Bastion/Tasks/create-session-managed-ssh.htm
resource "oci_bastion_session" "managed_ssh" {
  bastion_id   = oci_bastion_bastion.bastion.id
  display_name = "admin-ssh-session"

  key_details {
    public_key_content = var.bastion_public_key
  }

  session_ttl_in_seconds = 10800

  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id                         = data.terraform_remote_state.instances.outputs.instance_ocid
    target_resource_operating_system_user_name = "ubuntu"
    target_resource_port                       = 22
  }
}
