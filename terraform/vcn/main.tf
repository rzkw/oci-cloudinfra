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
  config_file_profile = "learn-terraform"
}

resource "oci_core_vcn" "internal" {
  dns_label      = "internal"
  cidr_block     = "172.16.0.0/20"
  compartment_id = var.compartment_id
  display_name   = "My internal VCN"
}

resource "oci_core_subnet" "dev" {
  vcn_id                     = oci_core_vcn.internal.id
  cidr_block                 = "172.16.0.0/24"
  compartment_id             = var.compartment_id
  display_name               = "Dev subnet"
  prohibit_public_ip_on_vnic = true
  dns_label                  = "dev"
}

resource "oci_core_subnet" "public" {
  vcn_id                     = oci_core_vcn.internal.id
  cidr_block                 = "172.16.1.0/24"
  compartment_id             = var.compartment_id
  display_name               = "Public-subnet1"
  prohibit_public_ip_on_vnic = false
  dns_label                  = "public"
}