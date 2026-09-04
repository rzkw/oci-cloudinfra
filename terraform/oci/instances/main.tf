resource "oci_core_instance" "this" {
  availability_domain                 = var.availability_domain
  compartment_id                      = var.compartment_ocid
  display_name                        = var.instance_display_name
  shape                               = var.shape
  state                               = var.instance_state
  is_pv_encryption_in_transit_enabled = true

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  shape_config {
    memory_in_gbs = var.memory_in_gbs
    ocpus         = var.ocpus
  }

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    plugins_config {
      name          = "Bastion"
      desired_state = "ENABLED"
    }
    plugins_config {
      name          = "Compute Instance Monitoring"
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
  }

  create_vnic_details {
    assign_public_ip = var.public_ip != "NONE"
    subnet_id        = var.subnet_ocid
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_keys != null ? var.ssh_public_keys : ""
    user_data           = var.user_data_path != null ? base64encode(file(var.user_data_path)) : null
    tailscale_auth_key  = var.tailscale_auth_key
  }

  source_details {
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    source_id               = var.source_ocid
    source_type             = "image"
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  timeouts {
    create = "25m"
  }
}
