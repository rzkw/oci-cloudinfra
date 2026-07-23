output "instance_ocids" {
  description = "OCIDs of created instances."
  value       = oci_core_instance.this[*].id
}

output "instance_private_ips" {
  description = "Private IP addresses of created instances."
  value       = oci_core_instance.this[*].private_ip
}
