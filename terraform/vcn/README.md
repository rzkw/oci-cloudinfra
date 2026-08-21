# VCN

Private VCN for dev workloads: subnet isolation, NAT egress, and same-subnet SSH ingress for the bastion private endpoint (bastion lives in [bastion/](../bastion/)).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | ~> 8.20 |

## Resources

| Name | Type |
|------|------|
| [oci_core_nat_gateway.nat-gateway](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_nat_gateway) | resource |
| [oci_core_route_table.dev](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_route_table) | resource |
| [oci_core_security_list.internal](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list) | resource |
| [oci_core_subnet.dev](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet) | resource |
| [oci_core_vcn.internal](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_vcn) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_compartment_ocid"></a> [compartment\_ocid](#input\_compartment\_ocid) | OCID from your tenancy page | `string` | n/a | yes |
| <a name="input_dev_subnet_cidr"></a> [dev\_subnet\_cidr](#input\_dev\_subnet\_cidr) | CIDR block of the dev subnet; also the SSH ingress source (bastion endpoint lives in this subnet) | `string` | `"172.16.0.0/24"` | no |
| <a name="input_region"></a> [region](#input\_region) | region where you have OCI tenancy | `string` | `"ap-melbourne-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dev_subnet_cidr"></a> [dev\_subnet\_cidr](#output\_dev\_subnet\_cidr) | CIDR of the dev subnet |
| <a name="output_dev_subnet_ocid"></a> [dev\_subnet\_ocid](#output\_dev\_subnet\_ocid) | OCID of the dev subnet |
| <a name="output_vcn_cidr"></a> [vcn\_cidr](#output\_vcn\_cidr) | CIDR block of the core VCN |
| <a name="output_vcn_state"></a> [vcn\_state](#output\_vcn\_state) | The state of the VCN. |
<!-- END_TF_DOCS -->