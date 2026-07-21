variable "compartment_ocid" {
  description = "OCID from your tenancy page"
  type        = string
}
variable "region" {
  description = "region where you have OCI tenancy"
  type        = string
  default     = "ap-melbourne-1"
}


variable "bastion_client_cidrs" {
  description = "CIDR blocks allowed to connect to the bastion public IP"
  type        = list(string)
  default     = null
}

variable "target_instance_ocid" {
  description = "OCID of the target compute instance for bastion sessions"
  type        = string
  default     = null
}

variable "target_instance_private_ip" {
  description = "Private IP of the target compute instance for bastion sessions"
  type        = string
  default     = null
}

variable "bastion_session_ssh_public_key" {
  description = "SSH public key for bastion managed SSH sessions"
  type        = string
  default     = null
  sensitive   = true
}

variable "instance_ocids" {
  description = "OCIDs of instances to reference (alternative to terraform_remote_state). Set via .tfvars."
  type        = list(string)
  default     = null
}