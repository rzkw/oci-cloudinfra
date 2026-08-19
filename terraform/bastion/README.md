<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | ~> 8.20 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_oci"></a> [oci](#provider\_oci) | 8.26.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [oci_bastion_bastion.bastion](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/bastion_bastion) | resource |
| [oci_bastion_session.managed_ssh](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/bastion_session) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_ssh_public_key_path"></a> [bastion\_ssh\_public\_key\_path](#input\_bastion\_ssh\_public\_key\_path) | value | `string` | `"~/.ssh/bastion_key.pub"` | no |
| <a name="input_client_cidr_block_allow_list"></a> [client\_cidr\_block\_allow\_list](#input\_client\_cidr\_block\_allow\_list) | List of CIDR blocks allowed to connect to the bastion | `string` | `"0.0.0.0/0"` | no |
| <a name="input_compartment_id"></a> [compartment\_id](#input\_compartment\_id) | value | `string` | n/a | yes |
| <a name="input_private_ip"></a> [private\_ip](#input\_private\_ip) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | region where you have OCI tenancy | `string` | `"ap-melbourne-1"` | no |
| <a name="input_target_resource_id"></a> [target\_resource\_id](#input\_target\_resource\_id) | OCID of the compute instance to connect to via bastion | `string` | n/a | yes |
| <a name="input_target_subnet_id"></a> [target\_subnet\_id](#input\_target\_subnet\_id) | n/a | `string` | n/a | yes |
| <a name="input_vcn_id"></a> [vcn\_id](#input\_vcn\_id) | VCN OCID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_private_endpoint_ip"></a> [bastion\_private\_endpoint\_ip](#output\_bastion\_private\_endpoint\_ip) | Bastion private endpoint IP, used in security list rules |
| <a name="output_managed_ssh_command"></a> [managed\_ssh\_command](#output\_managed\_ssh\_command) | SSH command to connect to instance via managed SSH session |
<!-- END_TF_DOCS -->