variable "compartment_ocid" {
  description = "OCID from your tenancy page"
  type        = string
}

variable "region" {
  description = "region where you have OCI tenancy"
  type        = string
  default     = "ap-melbourne-1"
}

variable "bastion_public_key" {
  description = "Public SSH key content used by the managed SSH session; the matching private key authenticates both hops"
  type        = string
}

variable "client_cidr_block_allow_list" {
  description = "CIDR blocks allowed to connect to the bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
