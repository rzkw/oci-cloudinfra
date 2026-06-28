variable "compartment_id" {
  description = "OCID from your tenancy page"
  type        = string
}
variable "region" {
  description = "region where you have OCI tenancy"
  type        = string
  default     = "ap-melbourne-1"
}

# variable "protocol" {
#   description = "protocol to allow ingress to VCN"
#   type = 
#   default = "6"
# }