# Bastion

Managed OCI Bastion service and SSH session for access to the private dev instance. Reads subnet OCID from vcn state and instance OCID from instances state via `terraform_remote_state`.

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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_public_key"></a> [bastion\_public\_key](#input\_bastion\_public\_key) | Public SSH key content used by the managed SSH session; the matching private key authenticates both hops | `string` | n/a | yes |
| <a name="input_client_cidr_block_allow_list"></a> [client\_cidr\_block\_allow\_list](#input\_client\_cidr\_block\_allow\_list) | CIDR blocks allowed to connect to the bastion | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_compartment_ocid"></a> [compartment\_ocid](#input\_compartment\_ocid) | OCID from your tenancy page | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | region where you have OCI tenancy | `string` | `"ap-melbourne-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_connection_details"></a> [connection\_details](#output\_connection\_details) | Ready-to-run SSH command; replace <privateKey> with the path to the private key matching var.bastion\_public\_key |
| <a name="output_session_ocid"></a> [session\_ocid](#output\_session\_ocid) | OCID of the managed SSH session (for CLI inspection) |
<!-- END_TF_DOCS -->
