# Required variables: compartment_ocid selects the tenancy compartment,
# target_resource_id is the instance the bastion session connects to, and
# bastion_public_key authenticates the managed SSH session (key_details is a
# required argument of oci_bastion_session). client_cidr_block_allow_list
# restricts which source IPs can open bastion sessions (default all).
# References:
#   https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/bastion_session
#   https://docs.oracle.com/en-us/iaas/Content/Bastion/Tasks/managingbastions.htm

variable "compartment_ocid" {
  description = "OCID from your tenancy page"
  type        = string
}
variable "region" {
  description = "region where you have OCI tenancy"
  type        = string
  default     = "ap-melbourne-1"
}

variable "target_resource_id" {
  description = "OCID of the compute instance to connect to via bastion"
  type        = string
}

variable "bastion_public_key" {
  description = "Public SSH key content used by the managed SSH session"
  type        = string
}

variable "client_cidr_block_allow_list" {
  description = "CIDR blocks allowed to connect to the bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "bastion_private_ip" {
  description = "Bastion private endpoint IP. Empty to skip SSH-from-bastion rule (deploy VCN first). Set after bastion apply."
  type        = string
  default     = ""
}
