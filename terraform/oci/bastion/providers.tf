# Reference: https://developer.hashicorp.com/terraform/language/backend/oci
# Key must stay distinct from other root modules — a shared key silently
# overwrites the other module's state (see PR #66/#67 era bug).

terraform {
  backend "oci" {
    bucket    = "tfstate"
    namespace = "axvczntoncvg"
    key       = "terraform/bastion/terraform.tfstate"
    region    = "ap-melbourne-1"
  }

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
