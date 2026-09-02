variable "region" {
  description = "the oci region where resources will be created"
  type        = string
  default     = "ap-melbourne-1"
}

# general oci parameters

variable "compartment_ocid" {
  description = "compartment ocid where to create all resources"
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "simple key-value pairs to tag the resources created using freeform tags."
  type        = map(string)
  default     = null
}

variable "defined_tags" {
  description = "predefined and scoped to a namespace to tag the resources created using defined tags."
  type        = map(string)
  default     = null
}

# compute instance parameters

variable "availability_domain" {
  description = "The availability domain to launch the instance in."
  type        = string
  default     = "KfOu:AP-MELBOURNE-1-AD-1"
}

variable "instance_display_name" {
  description = "(Updatable) A user-friendly name for the instance. Does not have to be unique, and it's changeable."
  type        = string
  default     = "VM"
}

variable "memory_in_gbs" {
  type        = number
  description = "(Updatable) The total amount of memory available to the instance, in gigabytes."
  default     = 24
}

variable "ocpus" {
  type        = number
  description = "(Updatable) The total number of OCPUs available to the instance."
  default     = 4
}

variable "instance_state" {
  type        = string
  description = "(Updatable) The target state for the instance. Could be set to RUNNING or STOPPED."
  default     = "RUNNING"

  validation {
    condition     = contains(["RUNNING", "STOPPED"], var.instance_state)
    error_message = "Accepted values are RUNNING or STOPPED."
  }
}

variable "shape" {
  description = "The shape of an instance."
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "source_ocid" {
  description = "The OCID of an image to use for the instance."
  type        = string
  default     = "ocid1.image.oc1.ap-melbourne-1.aaaaaaaawr3xahtf7zbw6uov2yawyerlfkm246qbtrku7cvcel7enu66y5tq"
}

# operating system parameters

variable "ssh_public_keys" {
  description = "Public SSH keys to be included in the ~/.ssh/authorized_keys file for the default user on the instance. To provide multiple keys, see docs/instance_ssh_keys.adoc."
  type        = string
  default     = null
  sensitive   = true

}

# networking parameters

variable "public_ip" {
  description = "Whether to create a Public IP to attach to primary vnic and which lifetime. Valid values are NONE, RESERVED or EPHEMERAL."
  type        = string
  default     = "NONE"
}

variable "subnet_ocid" {
  description = "OCID of subnet to create instance in"
  type        = string
}

# storage parameters

variable "boot_volume_size_in_gbs" {
  description = "The size of the boot volume in GBs."
  type        = number
  default     = 50
}

# cloud-init parameters

variable "tailscale_auth_key" {
  description = "Tailscale pre-authentication key for joining the tailnet"
  type        = string
  sensitive   = true
}

variable "vault_password" {
  description = "Ansible vault password for cloud-init provisioning"
  type        = string
  sensitive   = true
}
