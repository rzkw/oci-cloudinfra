# oci-cloudinfra

Walkable LLC's Terraform config for our OCI virtual network.

## Modules

### VCN

`terraform/vcn/` — virtual cloud network, subnets, routing, security lists.

<!-- BEGIN_TF_DOCS vcn -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | ~> 8.20 |

## Resources

| Name | Type |
|------|------|
| [oci_bastion_bastion.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/bastion_bastion) | resource |
| [oci_bastion_session.managed_ssh](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/bastion_session) | resource |
| [oci_core_internet_gateway.internal](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_internet_gateway) | resource |
| [oci_core_route_table.dev](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_route_table) | resource |
| [oci_core_security_list.internal](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list) | resource |
| [oci_core_service_gateway.internal](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_service_gateway) | resource |
| [oci_core_subnet.dev](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet) | resource |
| [oci_core_vcn.internal](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_vcn) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_client_cidrs"></a> [bastion\_client\_cidrs](#input\_bastion\_client\_cidrs) | CIDR blocks allowed to connect to the bastion public IP | `list(string)` | `null` | no |
| <a name="input_bastion_session_ssh_public_key"></a> [bastion\_session\_ssh\_public\_key](#input\_bastion\_session\_ssh\_public\_key) | SSH public key for bastion managed SSH sessions | `string` | `null` | no |
| <a name="input_compartment_ocid"></a> [compartment\_ocid](#input\_compartment\_ocid) | OCID from your tenancy page | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | region where you have OCI tenancy | `string` | `"ap-melbourne-1"` | no |
| <a name="input_target_instance_ocid"></a> [target\_instance\_ocid](#input\_target\_instance\_ocid) | OCID of the target compute instance for bastion sessions | `string` | `null` | no |
| <a name="input_target_instance_private_ip"></a> [target\_instance\_private\_ip](#input\_target\_instance\_private\_ip) | Private IP of the target compute instance for bastion sessions | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dev_subnet_cidr"></a> [dev\_subnet\_cidr](#output\_dev\_subnet\_cidr) | CIDR of the dev subnet |
| <a name="output_dev_subnet_ocid"></a> [dev\_subnet\_ocid](#output\_dev\_subnet\_ocid) | OCID of the dev subnet |
| <a name="output_vcn_cidr"></a> [vcn\_cidr](#output\_vcn\_cidr) | CIDR block of the core VCN |
| <a name="output_vcn_state"></a> [vcn\_state](#output\_vcn\_state) | The state of the VCN. |
<!-- END_TF_DOCS -->
<!-- END_TF_DOCS vcn -->

### Instances

`terraform/instances/` — compute (A1.Flex), uses remote compute-instance module.

<!-- BEGIN_TF_DOCS instances -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | ~> 8.20 |

## Resources

| Name | Type |
|------|------|
| [oci_core_instance.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance) | resource |
| [oci_core_volume.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_volume) | resource |
| [oci_core_volume_attachment.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_volume_attachment) | resource |
| [oci_core_volume_backup_policy_assignment.boot_volume](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_volume_backup_policy_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_block_storage_sizes_in_gbs"></a> [block\_storage\_sizes\_in\_gbs](#input\_block\_storage\_sizes\_in\_gbs) | Sizes of volumes to create and attach to each instance. | `list(number)` | `[]` | no |
| <a name="input_boot_volume_backup_policy"></a> [boot\_volume\_backup\_policy](#input\_boot\_volume\_backup\_policy) | Choose between default backup policies : gold, silver, bronze. Use disabled to affect no backup policy on the Boot Volume. | `string` | `"disabled"` | no |
| <a name="input_boot_volume_size_in_gbs"></a> [boot\_volume\_size\_in\_gbs](#input\_boot\_volume\_size\_in\_gbs) | The size of the boot volume in GBs. | `number` | `50` | no |
| <a name="input_compartment_ocid"></a> [compartment\_ocid](#input\_compartment\_ocid) | compartment ocid where to create all resources | `string` | `null` | no |
| <a name="input_defined_tags"></a> [defined\_tags](#input\_defined\_tags) | predefined and scoped to a namespace to tag the resources created using defined tags. | `map(string)` | `null` | no |
| <a name="input_freeform_tags"></a> [freeform\_tags](#input\_freeform\_tags) | simple key-value pairs to tag the resources created using freeform tags. | `map(string)` | `null` | no |
| <a name="input_instance_ad_number"></a> [instance\_ad\_number](#input\_instance\_ad\_number) | The availability domain number of the instance. If none is provided, it will start with AD-1 and continue in round-robin. | `number` | `1` | no |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | Number of identical instances to launch from a single module. | `number` | `1` | no |
| <a name="input_instance_display_name"></a> [instance\_display\_name](#input\_instance\_display\_name) | (Updatable) A user-friendly name for the instance. Does not have to be unique, and it's changeable. | `string` | `"VM"` | no |
| <a name="input_instance_flex_memory_in_gbs"></a> [instance\_flex\_memory\_in\_gbs](#input\_instance\_flex\_memory\_in\_gbs) | (Updatable) The total amount of memory available to the instance, in gigabytes. | `number` | `12` | no |
| <a name="input_instance_flex_ocpus"></a> [instance\_flex\_ocpus](#input\_instance\_flex\_ocpus) | (Updatable) The total number of OCPUs available to the instance. | `number` | `2` | no |
| <a name="input_instance_state"></a> [instance\_state](#input\_instance\_state) | (Updatable) The target state for the instance. Could be set to RUNNING or STOPPED. | `string` | `"RUNNING"` | no |
| <a name="input_public_ip"></a> [public\_ip](#input\_public\_ip) | Whether to create a Public IP to attach to primary vnic and which lifetime. Valid values are NONE, RESERVED or EPHEMERAL. | `string` | `"NONE"` | no |
| <a name="input_region"></a> [region](#input\_region) | the oci region where resources will be created | `string` | `"ap-melbourne-1"` | no |
| <a name="input_shape"></a> [shape](#input\_shape) | The shape of an instance. | `string` | `"VM.Standard.A1.Flex"` | no |
| <a name="input_source_ocid"></a> [source\_ocid](#input\_source\_ocid) | The OCID of an image or a boot volume to use, depending on the value of source\_type. | `string` | `"ocid1.image.oc1.ap-melbourne-1.aaaaaaaawr3xahtf7zbw6uov2yawyerlfkm246qbtrku7cvcel7enu66y5tq"` | no |
| <a name="input_source_type"></a> [source\_type](#input\_source\_type) | The source type for the instance. | `string` | `"image"` | no |
| <a name="input_ssh_public_keys"></a> [ssh\_public\_keys](#input\_ssh\_public\_keys) | Public SSH keys to be included in the ~/.ssh/authorized\_keys file for the default user on the instance. To provide multiple keys, see docs/instance\_ssh\_keys.adoc. | `string` | `null` | no |
| <a name="input_subnet_ocids"></a> [subnet\_ocids](#input\_subnet\_ocids) | OCID of subnet to create instance in | `list(string)` | n/a | yes |
| <a name="input_tailscale_auth_key"></a> [tailscale\_auth\_key](#input\_tailscale\_auth\_key) | Tailscale pre-authentication key for joining the tailnet | `string` | n/a | yes |
| <a name="input_user_data_path"></a> [user\_data\_path](#input\_user\_data\_path) | Path to the cloud-init user\_data script | `string` | `"user-data.yaml"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_flex"></a> [instance\_flex](#output\_instance\_flex) | Private and Public IPs for each instance. |
<!-- END_TF_DOCS -->
<!-- END_TF_DOCS instances -->

### Budget

`terraform/budget/` — cost alerts (email).

<!-- BEGIN_TF_DOCS budget -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | ~> 8.20 |

## Resources

| Name | Type |
|------|------|
| [oci_budget_alert_rule.actual](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/budget_alert_rule) | resource |
| [oci_budget_alert_rule.forecast](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/budget_alert_rule) | resource |
| [oci_budget_budget.dollar_budget](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/budget_budget) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_budget_alert_email"></a> [budget\_alert\_email](#input\_budget\_alert\_email) | Email address for budget alerts | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | OCI region | `string` | `"ap-melbourne-1"` | no |
| <a name="input_tenancy_ocid"></a> [tenancy\_ocid](#input\_tenancy\_ocid) | OCID of the tenancy | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- END_TF_DOCS budget -->
