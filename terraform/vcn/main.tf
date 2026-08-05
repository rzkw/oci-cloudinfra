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
  
  ingress_security_rules {
    protocol = "6"
    source   = "${oci_bastion_bastion.bastion.private_endpoint_ip_address}"
    source_type = "CIDR_BLOCK"
    description = "Allow SSH from OCI Bastion private endpoint"
    
    tcp_options {
      min = 22
      max = 22
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
