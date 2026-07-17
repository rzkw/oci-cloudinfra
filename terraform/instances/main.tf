data "oci_identity_availability_domains" "ad" {
  compartment_id = var.compartment_ocid
}

data "oci_core_volume_backup_policies" "default_backup_policies" {}

locals {
  ads = [
    for i in data.oci_identity_availability_domains.ad.availability_domains : i.name
  ]
  backup_policies = {
    for i in data.oci_core_volume_backup_policies.default_backup_policies.volume_backup_policies :
    i.display_name => i.id
  }
}

resource "oci_core_instance" "this" {
  count                               = var.instance_count
  availability_domain                 = var.instance_ad_number != null ? element(local.ads, var.instance_ad_number - 1) : element(local.ads, count.index)
  compartment_id                      = var.compartment_ocid
  display_name                        = var.instance_count > 1 ? "${var.instance_display_name}_${count.index + 1}" : var.instance_display_name
  shape                               = var.shape
  state                               = var.instance_state
  is_pv_encryption_in_transit_enabled = true

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  shape_config {
    memory_in_gbs = var.instance_flex_memory_in_gbs
    ocpus         = var.instance_flex_ocpus
  }

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    plugins_config {
      name          = "Oracle Autonomous Linux"
      desired_state = "DISABLED"
    }
    plugins_config {
      name          = "Bastion"
      desired_state = "ENABLED"
    }
    plugins_config {
      name          = "Block Volume Management"
      desired_state = "DISABLED"
    }
    plugins_config {
      name          = "Custom Logs Monitoring"
      desired_state = "ENABLED"
    }
    plugins_config {
      name          = "Management Agent"
      desired_state = "DISABLED"
    }
    plugins_config {
      name          = "Compute Instance Monitoring"
      desired_state = "ENABLED"
    }
    plugins_config {
      name          = "OS Management Service Agent"
      desired_state = "ENABLED"
    }
    plugins_config {
      name          = "Compute Instance Run Command"
      desired_state = "ENABLED"
    }
    plugins_config {
      name          = "Vulnerability Scanning"
      desired_state = "ENABLED"
    }
    plugins_config {
      name          = "Oracle Java Management Service"
      desired_state = "DISABLED"
    }
  }

  create_vnic_details {
    assign_public_ip = var.public_ip != "NONE"
    subnet_id        = element(var.subnet_ocids, count.index)
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_keys != null ? var.ssh_public_keys : ""
    user_data           = var.user_data_path != null ? base64encode(file(var.user_data_path)) : null
  }

  source_details {
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    source_id               = var.source_ocid
    source_type             = var.source_type

  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  timeouts {
    create = "25m"
  }
}

resource "oci_core_volume_backup_policy_assignment" "boot_volume" {
  count     = var.boot_volume_backup_policy != "disabled" ? var.instance_count : 0
  asset_id  = oci_core_instance.this[*].boot_volume_id[count.index]
  policy_id = local.backup_policies[var.boot_volume_backup_policy]
}

resource "oci_core_volume" "this" {
  count               = var.instance_count * length(var.block_storage_sizes_in_gbs)
  availability_domain = oci_core_instance.this[count.index % var.instance_count].availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = "${oci_core_instance.this[count.index % var.instance_count].display_name}_volume${floor(count.index / var.instance_count)}"
  size_in_gbs         = element(var.block_storage_sizes_in_gbs, floor(count.index / var.instance_count))
  freeform_tags       = var.freeform_tags
  defined_tags        = var.defined_tags
}

resource "oci_core_volume_attachment" "this" {
  count                               = var.instance_count * length(var.block_storage_sizes_in_gbs)
  attachment_type                     = "paravirtualized"
  instance_id                         = oci_core_instance.this[count.index % var.instance_count].id
  volume_id                           = oci_core_volume.this[count.index].id
  is_pv_encryption_in_transit_enabled = true
}

locals {
  instances_summary = [
    for i in oci_core_instance.this : <<-EOT
    ${i.display_name}
    Primary-PublicIP: ${i.public_ip != "" ? i.public_ip : "N/A"}
    Primary-PrivateIP: ${i.private_ip}
    EOT
  ]
}

output "instance_flex" {
  description = "Private and Public IPs for each instance."
  value       = local.instances_summary
}
