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