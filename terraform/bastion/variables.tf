variable "compartment_id" {
  description = "value"
  type        = string
}

variable "vcn_id" {
  description = "VCN OCID"
  type        = string
}

variable "private_ip" {
  type = string
}

variable "bastion_ssh_public_key_path" {
  description = "value"
  type        = string
  default     = "~/.ssh/bastion_key.pub"
}

variable "region" {
  description = "region where you have OCI tenancy"
  type        = string
  default     = "ap-melbourne-1"
}

variable "target_subnet_id" {
  type = string
}

variable "client_cidr_block_allow_list" {
  description = "List of CIDR blocks allowed to connect to the bastion"
  default     = "0.0.0.0/0"
}

variable "target_resource_id" {
  description = "OCID of the compute instance to connect to via bastion"
  type = string
  
}