# This block creates a Reserved Public IP from Oracle IP Pool; https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_public_ip

data "oci_core_private_ips" "instance_primary" {
  subnet_id  = var.subnet_ocid
  ip_address = oci_core_instance.this.private_ip
}

resource "oci_core_public_ip" "pubip" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  private_ip_id  = data.oci_core_private_ips.instance_primary.private_ips[0].id
}

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
    assign_public_ip = false
    subnet_id        = var.subnet_ocid
  }

  metadata = {
    ssh_authorized_keys  = var.ssh_public_keys
    agent_ssh_public_key = var.agent_ssh_public_key
    user_data            = base64encode(file(var.user_data_path != null ? var.user_data_path : "${path.module}/../../../user-data.yaml"))
    tailscale_auth_key   = var.tailscale_auth_key
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
