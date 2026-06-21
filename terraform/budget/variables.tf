variable "tenancy_ocid" {
  description = "OCID of the tenancy"
  type        = string
}

variable "budget_alert_email" {
  description = "Email address for budget alerts"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "ap-melbourne-1"
}
