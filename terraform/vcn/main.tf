terraform {
  backend "oci" {
    bucket    = "tfstate"
    namespace = "axvczntoncvg"
  }

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.20"
    }
  }
}

provider "oci" {
  region              = var.region
  config_file_profile = "DEFAULT"
}

resource "oci_core_vcn" "internal" {
  dns_label      = "internal"
  cidr_block     = "172.16.0.0/20"
  compartment_id = var.compartment_ocid
  display_name   = "My internal VCN"
}

# Internet Gateway
resource "oci_core_internet_gateway" "internal" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.internal.id
  display_name   = "Internal Internet Gateway"
  enabled        = true
}

# Route table for dev subnet (public, via IGW)
resource "oci_core_route_table" "dev" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.internal.id
  display_name   = "Dev Route Table"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internal.id
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

  ingress_security_rules {
    protocol = "6"
    source   = "103.154.138.8/32"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "17"
    source   = "103.154.138.8/32"
    udp_options {
      min = 41641
      max = 41641
    }
  }
}

# Dev subnet — public (has IGW route) but no public IPs allowed
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

# Bastion — managed SSH access to the instance
resource "oci_bastion_bastion" "this" {
  count                        = var.target_instance_ocid != null ? 1 : 0
  bastion_type                 = "standard"
  compartment_id               = var.compartment_ocid
  target_subnet_id             = oci_core_subnet.dev.id
  client_cidr_block_allow_list = var.bastion_client_cidrs
  name                         = "bastion-${oci_core_vcn.internal.display_name}"
}

resource "oci_bastion_session" "managed_ssh" {
  count      = var.target_instance_ocid != null ? 1 : 0
  bastion_id = oci_bastion_bastion.this[0].id
  target_resource_details {
    session_type                       = "MANAGED_SSH"
    target_resource_id                 = var.target_instance_ocid
    target_resource_private_ip_address = var.target_instance_private_ip
    target_resource_port               = 22
  }
  key_details {
    public_key_content = var.bastion_session_ssh_public_key
  }
  display_name           = "managed-ssh-vm"
  session_ttl_in_seconds = 10800
}
