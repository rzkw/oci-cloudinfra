output "instance_ocid" {
  description = "OCID of the created instance."
  value       = oci_core_instance.this.id
}

output "instance_private_ip" {
  description = "Private IP address of the created instance."
  value       = oci_core_instance.this.private_ip
}
