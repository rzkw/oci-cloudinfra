variable "compartment_id" {
    description = "value"
    type = string
}

variable "vcn_id" {
    description = "VCN OCID"
    type = string
}

variable "private_ip" {
  type = string
}

variable "bastion_ssh_public_key_path" {
  description = "value"
  type = string
  default = "~/.ssh/bastion_key.pub"
}