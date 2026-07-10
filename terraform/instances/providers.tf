terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.20"
    }
  }
}

provider "oci" {
  region              = var.region
  config_file_profile = "DEFAULT"
}
