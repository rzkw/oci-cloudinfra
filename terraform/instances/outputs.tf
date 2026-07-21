output "instance_ocids" {
  description = "OCIDs of created instances."
  value       = oci_core_instance.this[*].id
}

output "instance_private_ips" {
  description = "Private IP addresses of created instances."
  value       = oci_core_instance.this[*].private_ip
}

output "instance_public_ips" {
  description = "Public IP addresses of created instances (empty if no public IP assigned)."
  value       = oci_core_instance.this[*].public_ip
}

output "instance_boot_volume_ids" {
  description = "Boot volume OCIDs of created instances."
  value       = oci_core_instance.this[*].boot_volume_id
}

output "instance_availability_domains" {
  description = "Availability domains of created instances."
  value       = oci_core_instance.this[*].availability_domain
}
