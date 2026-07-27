# VCN

Virtual cloud network with a private dev subnet, internet and service gateways, and bastion access.

## Resources

| Name | Description |
|------|-------------|
| `oci_core_vcn.internal` | VCN (`172.16.0.0/20`) |
| `oci_core_subnet.dev` | Private dev subnet (`172.16.0.0/24`) |
| `oci_core_internet_gateway.internal` | Outbound internet gateway |
| `oci_core_service_gateway.internal` | Private access to OCI services |
| `oci_core_route_table.dev` | Route table (IGW + SG routes) |
| `oci_core_security_list.internal` | SSH + Tailscale UDP 41641 from home IP |
| `oci_bastion_bastion.this` | Standard bastion (conditional) |
| `oci_bastion_session.managed_ssh` | Managed SSH session, 3h TTL (conditional) |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `compartment_ocid` | OCID from your tenancy page | `string` | n/a |
| `region` | Region where you have OCI tenancy | `string` | `"ap-melbourne-1"` |
| `bastion_client_cidrs` | CIDR blocks allowed to connect to the bastion public IP | `list(string)` | `null` |
| `target_instance_ocid` | OCID of the target compute instance for bastion sessions | `string` | `null` |
| `target_instance_private_ip` | Private IP of the target compute instance for bastion sessions | `string` | `null` |

## Outputs

| Name | Description |
|------|-------------|
| `vcn_cidr` | CIDR block of the VCN |

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
