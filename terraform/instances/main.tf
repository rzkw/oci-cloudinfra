// Copyright (c) 2018, 2021 Oracle and/or its affiliates

terraform {
  required_version = ">= 1.5"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "8.2.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# * This modified module will create a Flex Compute Instance within Always Free resources, using default values: 1 OCPU, 8 GB memory.

module "instance_flex" {
  source = "git::https://github.com/oracle-terraform-modules/terraform-oci-compute-instance.git?ref=b19dbe063ab82529c9ef71c92d1472fba2d30595"

  # general oci parameters
  compartment_ocid = var.compartment_ocid
  freeform_tags    = var.freeform_tags
  defined_tags     = var.defined_tags

  # compute instance parameters
  ad_number                   = var.instance_ad_number
  instance_count              = var.instance_count
  instance_display_name       = var.instance_display_name
  instance_state              = var.instance_state
  shape                       = var.shape
  source_ocid                 = var.source_ocid
  source_type                 = var.source_type
  instance_flex_memory_in_gbs = var.instance_flex_memory_in_gbs # changed default to 8GB
  instance_flex_ocpus         = var.instance_flex_ocpus         # changed default to 1
  cloud_agent_plugins = {
    autonomous_linux       = "DISABLED"
    bastion                = "ENABLED"
    vulnerability_scanning = "ENABLED"
    osms                   = "ENABLED"
    management             = "DISABLED"
    custom_logs            = "ENABLED"
    run_command            = "ENABLED"
    monitoring             = "ENABLED"
    block_volume_mgmt      = "DISABLED"
  }

  # operating system parameters
  ssh_public_keys = var.ssh_public_keys

  # networking parameters
  public_ip    = var.public_ip # NONE, RESERVED or EPHEMERAL
  subnet_ocids = var.subnet_ocids

  # storage parameters
  boot_volume_backup_policy  = var.boot_volume_backup_policy
  block_storage_sizes_in_gbs = var.block_storage_sizes_in_gbs
}

output "instance_flex" {
  description = "ocid of created instances."
  value       = module.instance_flex.instances_summary
}
