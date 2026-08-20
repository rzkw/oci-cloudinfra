Private VCN for dev workloads: subnet isolation, NAT egress, and a managed OCI Bastion for SSH access to private instances.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | ~> 8.20 |

## Resources

| Name | Type |
|------|------|
| [oci_bastion_bastion.bastion](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/bastion_bastion) | resource |
| [oci_bastion_session.managed_ssh](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/bastion_session) | resource |
| [oci_core_nat_gateway.nat-gateway](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_nat_gateway) | resource |
| [oci_core_route_table.dev](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_route_table) | resource |
| [oci_core_security_list.internal](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list) | resource |
| [oci_core_subnet.dev](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet) | resource |
| [oci_core_vcn.internal](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_vcn) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_private_ip"></a> [bastion\_private\_ip](#input\_bastion\_private\_ip) | Bastion private endpoint IP. Empty to skip SSH-from-bastion rule (deploy VCN first). Set after bastion apply. | `string` | `""` | no |
| <a name="input_bastion_public_key"></a> [bastion\_public\_key](#input\_bastion\_public\_key) | Public SSH key content used by the managed SSH session | `string` | n/a | yes |
| <a name="input_client_cidr_block_allow_list"></a> [client\_cidr\_block\_allow\_list](#input\_client\_cidr\_block\_allow\_list) | CIDR blocks allowed to connect to the bastion | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_compartment_ocid"></a> [compartment\_ocid](#input\_compartment\_ocid) | OCID from your tenancy page | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | region where you have OCI tenancy | `string` | `"ap-melbourne-1"` | no |
| <a name="input_target_resource_id"></a> [target\_resource\_id](#input\_target\_resource\_id) | OCID of the compute instance to connect to via bastion | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_private_endpoint_ip"></a> [bastion\_private\_endpoint\_ip](#output\_bastion\_private\_endpoint\_ip) | Bastion private endpoint IP, used in security list rules |
| <a name="output_dev_subnet_cidr"></a> [dev\_subnet\_cidr](#output\_dev\_subnet\_cidr) | CIDR of the dev subnet |
| <a name="output_dev_subnet_ocid"></a> [dev\_subnet\_ocid](#output\_dev\_subnet\_ocid) | OCID of the dev subnet |
| <a name="output_vcn_cidr"></a> [vcn\_cidr](#output\_vcn\_cidr) | CIDR block of the core VCN |
| <a name="output_vcn_state"></a> [vcn\_state](#output\_vcn\_state) | The state of the VCN. |
<!-- END_TF_DOCS -->
