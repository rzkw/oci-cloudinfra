output "vcn_state" {
  description = "The state of the VCN."
  value       = oci_core_vcn.internal.state
}

output "vcn_cidr" {
  description = "CIDR block of the core VCN"
  value       = oci_core_vcn.internal.cidr_block
}

output "dev_subnet_ocid" {
  description = "OCID of the dev subnet"
  value       = oci_core_subnet.dev.id
}

output "dev_subnet_cidr" {
  description = "CIDR of the dev subnet"
  value       = oci_core_subnet.dev.cidr_block
}
