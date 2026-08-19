# Reference: https://blog.victorsilva.com.uy/oci-bastion-service-terraform/; https://foggykitchen.com/2021/06/18/oci-bastion-service-terraform/

resource "oci_bastion_bastion" "bastion" {
  bastion_type     = "STANDARD"
  compartment_id   = var.compartment_id
  target_subnet_id = var.target_subnet_id
  name             = "dev-bastion"

  client_cidr_block_allow_list = var.client_cidr_block_allow_list
  max_session_ttl_in_seconds   = 36000
}

resource "oci_bastion_session" "managed_ssh" {
  bastion_id   = oci_bastion_bastion.bastion
  display_name = "admin-ssh-session"

  key_details {
    public_key_content = file(var.bastion_ssh_public_key_path)
  }

  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id                         = var.target_resource_id
    target_resource_operating_system_user_name = "ubuntu"
    target_resource_port                       = 22
  }
}

output "managed_ssh_command" {
  description = "SSH command to connect to instance via managed SSH session"
  value       = <<-EOT
    ssh -i <private_key_path> \
      -o ProxyCommand="ssh -i <private_key_path> -W %h:%p -p 22 ${oci_bastion_session.managed_ssh.id}@host.bastion.${var.region}.oci.oraclecloud.com" \
      -p 22 ubuntu@${oci_core_instance.this.private_ip}
    EOT
}

output "bastion_private_endpoint_ip" {
  description = "Bastion private endpoint IP, used in security list rules"
  value       = oci_bastion_bastion.bastion.private_endpoint_ip_address

}