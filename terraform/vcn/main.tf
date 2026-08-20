resource "oci_core_vcn" "internal" {
  dns_label      = "internal"
  cidr_block     = "172.16.0.0/20"
  compartment_id = var.compartment_ocid
  display_name   = "My internal VCN"
}

# 05/08/2026 Changed to NAT Gateway. Ref: https://foggykitchen.com/2018/11/05/oci-nat-gateway-terraform/

resource "oci_core_nat_gateway" "nat-gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.internal.id
  display_name   = "NAT Gateway"
}

# Route table for dev subnet — NAT for outbound internet
resource "oci_core_route_table" "dev" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.internal.id
  display_name   = "Dev Route Table"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat-gateway.id
  }
}

# Security list — only allow UDP 41641 inbound (Tailscale) and SSH from home
resource "oci_core_security_list" "internal" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.internal.id
  display_name   = "Internal Security List"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Allow SSH from bastion private endpoint only. Reference: https://blog.victorsilva.com.uy/oci-bastion-service-terraform/
  # Conditional on var.bastion_private_ip to break the bastion→subnet→security_list cycle
  # and allow deploying VCN before bastion. Set var.bastion_private_ip after bastion apply.

  dynamic "ingress_security_rules" {
    for_each = var.bastion_private_ip != "" ? [1] : []
    content {
      protocol    = "6"
      source      = var.bastion_private_ip
      source_type = "CIDR_BLOCK"
      description = "Allow SSH from OCI Bastion private endpoint"

      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  ingress_security_rules {
    protocol = "17"
    source   = "0.0.0.0/0"
    udp_options {
      min = 41641
      max = 41641
    }
  }
}

# Dev subnet — public (has NAT route) but no public IPs allowed
resource "oci_core_subnet" "dev" {
  vcn_id                     = oci_core_vcn.internal.id
  cidr_block                 = "172.16.0.0/24"
  compartment_id             = var.compartment_ocid
  display_name               = "dev"
  prohibit_public_ip_on_vnic = true
  dns_label                  = "dev"
  route_table_id             = oci_core_route_table.dev.id
  security_list_ids          = [oci_core_security_list.internal.id]
}

# Bastion — managed SSH access to instances. Reference: https://blog.victorsilva.com.uy/oci-bastion-service-terraform/
resource "oci_bastion_bastion" "bastion" {
  bastion_type     = "STANDARD"
  compartment_id   = var.compartment_ocid
  target_subnet_id = oci_core_subnet.dev.id
  name             = "dev-bastion"

  client_cidr_block_allow_list = var.client_cidr_block_allow_list
  max_session_ttl_in_seconds   = 36000
}

resource "oci_bastion_session" "managed_ssh" {
  bastion_id   = oci_bastion_bastion.bastion.id
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
