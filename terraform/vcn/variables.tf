# Required variables: compartment_ocid selects the tenancy compartment.
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

variable "dev_subnet_cidr" {
  description = "CIDR block of the dev subnet; also the SSH ingress source (bastion endpoint lives in this subnet)"
  type        = string
  default     = "172.16.0.0/24"
}
