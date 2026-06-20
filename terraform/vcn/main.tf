terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

provider "oci" {
  region              = var.region
  auth                = "SecurityToken"
  config_file_profile = "DEFAULT"
}

resource "oci_core_vcn" "internal" {
  dns_label      = "internal"
  cidr_block     = "172.16.0.0/20"
  compartment_id = var.compartment_id
  display_name   = "My internal VCN"
}

# Internet Gateway
resource "oci_core_internet_gateway" "internal" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.internal.id
  display_name   = "Internal Internet Gateway"
  enabled        = true
}

# Route table for dev subnet (public, via IGW)
resource "oci_core_route_table" "dev" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.internal.id
  display_name   = "Dev Route Table"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internal.id
  }
}

# Route table for prod subnet (public, via IGW)
resource "oci_core_route_table" "prod" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.internal.id
  display_name   = "Prod Route Table"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internal.id
  }
}

# Security list — only allow UDP 41641 inbound (Tailscale)
resource "oci_core_security_list" "internal" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.internal.id
  display_name   = "Internal Security List"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "17" # UDP
    source   = "0.0.0.0/0"
    udp_options {
      source_port_range {
        min = 41641
        max = 41641
      }
    }
  }
}

# Dev subnet — public (has IGW route) but no public IPs allowed
resource "oci_core_subnet" "dev" {
  vcn_id                     = oci_core_vcn.internal.id
  cidr_block                 = "172.16.0.0/24"
  compartment_id             = var.compartment_id
  display_name               = "dev"
  prohibit_public_ip_on_vnic = true
  dns_label                  = "dev"
  route_table_id             = oci_core_route_table.dev.id
  security_list_ids          = [oci_core_security_list.internal.id]
}

# Prod subnet — public (has IGW route), public IPs allowed
resource "oci_core_subnet" "prod" {
  vcn_id                     = oci_core_vcn.internal.id
  cidr_block                 = "172.16.1.0/24"
  compartment_id             = var.compartment_id
  display_name               = "prod"
  prohibit_public_ip_on_vnic = false
  dns_label                  = "prod"
  route_table_id             = oci_core_route_table.prod.id
  security_list_ids          = [oci_core_security_list.internal.id]
}
