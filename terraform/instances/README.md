# Instances

A1.Flex compute instance with cloud-init bootstrapping, Tailscale mesh, and optional block volumes.

## Resources

| Name | Description |
|------|-------------|
| `oci_core_instance.this` | Compute instance (A1.Flex) |
| `oci_core_volume.this` | Block volumes (conditional) |
| `oci_core_volume_attachment.this` | Volume attachments (conditional) |
| `oci_core_volume_backup_policy_assignment.boot_volume` | Boot volume backup policy (conditional) |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `compartment_ocid` | Compartment OCID | `string` | n/a |
| `subnet_ocids` | Subnet OCIDs for instance placement | `list(string)` | n/a |
| `region` | OCI region | `string` | `"ap-melbourne-1"` |
| `instance_count` | Number of identical instances | `number` | `1` |
| `instance_display_name` | Instance display name | `string` | `"VM"` |
| `instance_ad_number` | Availability domain number | `number` | `1` |
| `shape` | Instance shape | `string` | `"VM.Standard.A1.Flex"` |
| `instance_flex_ocpus` | OCPUs for flex shape | `number` | `2` |
| `instance_flex_memory_in_gbs` | Memory in GBs for flex shape | `number` | `12` |
| `instance_state` | Target state (RUNNING or STOPPED) | `string` | `"RUNNING"` |
| `source_ocid` | Image or boot volume OCID | `string` | `"ocid1.image..."` |
| `source_type` | Source type | `string` | `"image"` |
| `public_ip` | Public IP assignment (NONE/RESERVED/EPHEMERAL) | `string` | `"NONE"` |
| `boot_volume_size_in_gbs` | Boot volume size in GBs | `number` | `50` |
| `boot_volume_backup_policy` | Backup policy (gold/silver/bronze/disabled) | `string` | `"disabled"` |
| `block_storage_sizes_in_gbs` | Additional block volume sizes | `list(number)` | `[]` |
| `user_data_path` | Path to cloud-init user_data script | `string` | `"user-data.yaml"` |

## Outputs

| Name | Description |
|------|-------------|
| `instance_private_ips` | Private IPs of created instances |

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
