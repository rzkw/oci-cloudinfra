# Instances

Single A1.Flex compute instance with its boot volume: cloud-init bootstraps Ansible, Tailscale for private access. Reads subnet OCID from vcn state via `terraform_remote_state`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | ~> 8.20 |

## Resources

| Name | Type |
|------|------|
| [oci_core_instance.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_domain"></a> [availability\_domain](#input\_availability\_domain) | The availability domain to launch the instance in. | `string` | `"KfOu:AP-MELBOURNE-1-AD-1"` | no |
| <a name="input_boot_volume_size_in_gbs"></a> [boot\_volume\_size\_in\_gbs](#input\_boot\_volume\_size\_in\_gbs) | The size of the boot volume in GBs. | `number` | `50` | no |
| <a name="input_compartment_ocid"></a> [compartment\_ocid](#input\_compartment\_ocid) | compartment ocid where to create all resources | `string` | `null` | no |
| <a name="input_defined_tags"></a> [defined\_tags](#input\_defined\_tags) | predefined and scoped to a namespace to tag the resources created using defined tags. | `map(string)` | `null` | no |
| <a name="input_freeform_tags"></a> [freeform\_tags](#input\_freeform\_tags) | simple key-value pairs to tag the resources created using freeform tags. | `map(string)` | `null` | no |
| <a name="input_instance_display_name"></a> [instance\_display\_name](#input\_instance\_display\_name) | (Updatable) A user-friendly name for the instance. Does not have to be unique, and it's changeable. | `string` | `"VM"` | no |
| <a name="input_instance_state"></a> [instance\_state](#input\_instance\_state) | (Updatable) The target state for the instance. Could be set to RUNNING or STOPPED. | `string` | `"RUNNING"` | no |
| <a name="input_memory_in_gbs"></a> [memory\_in\_gbs](#input\_memory\_in\_gbs) | (Updatable) The total amount of memory available to the instance, in gigabytes. | `number` | `24` | no |
| <a name="input_ocpus"></a> [ocpus](#input\_ocpus) | (Updatable) The total number of OCPUs available to the instance. | `number` | `4` | no |
| <a name="input_public_ip"></a> [public\_ip](#input\_public\_ip) | Whether to create a Public IP to attach to primary vnic and which lifetime. Valid values are NONE, RESERVED or EPHEMERAL. | `string` | `"NONE"` | no |
| <a name="input_region"></a> [region](#input\_region) | the oci region where resources will be created | `string` | `"ap-melbourne-1"` | no |
| <a name="input_shape"></a> [shape](#input\_shape) | The shape of an instance. | `string` | `"VM.Standard.A1.Flex"` | no |
| <a name="input_source_ocid"></a> [source\_ocid](#input\_source\_ocid) | The OCID of an image to use for the instance. | `string` | `"ocid1.image.oc1.ap-melbourne-1.aaaaaaaawr3xahtf7zbw6uov2yawyerlfkm246qbtrku7cvcel7enu66y5tq"` | no |
| <a name="input_ssh_public_keys"></a> [ssh\_public\_keys](#input\_ssh\_public\_keys) | Public SSH keys to be included in the ~/.ssh/authorized\_keys file for the default user on the instance. To provide multiple keys, see docs/instance\_ssh\_keys.adoc. | `string` | `null` | no |
| <a name="input_subnet_ocid"></a> [subnet\_ocid](#input\_subnet\_ocid) | OCID of subnet to create instance in | `string` | n/a | yes |
| <a name="input_tailscale_auth_key"></a> [tailscale\_auth\_key](#input\_tailscale\_auth\_key) | Tailscale pre-authentication key for joining the tailnet | `string` | n/a | yes |
| <a name="input_user_data_path"></a> [user\_data\_path](#input\_user\_data\_path) | Path to the cloud-init user\_data script | `string` | `"user-data.yaml"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_ocid"></a> [instance\_ocid](#output\_instance\_ocid) | OCID of the created instance. |
| <a name="output_instance_private_ip"></a> [instance\_private\_ip](#output\_instance\_private\_ip) | Private IP address of the created instance. |
<!-- END_TF_DOCS -->
