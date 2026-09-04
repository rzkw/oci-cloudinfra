output "connection_details" {
  description = "Ready-to-run SSH command; replace <privateKey> with the path to the private key matching var.bastion_public_key"
  value       = oci_bastion_session.managed_ssh.ssh_metadata.command
}

output "session_ocid" {
  description = "OCID of the managed SSH session (for CLI inspection)"
  value       = oci_bastion_session.managed_ssh.id
}
