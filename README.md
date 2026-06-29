# oci-cloudinfra

Configuration, documentation etc of my virtual network on OCI.

## Modules

### VCN

`terraform/vcn/` — virtual cloud network, subnets, routing, security lists.

<!-- BEGIN_TF_DOCS vcn -->
<!-- END_TF_DOCS vcn -->

### Instances

`terraform/instances/` — compute (A1.Flex), uses remote compute-instance module.

<!-- BEGIN_TF_DOCS instances -->
<!-- END_TF_DOCS instances -->

### Budget

`terraform/budget/` — cost alerts (email), currently WIP.

<!-- BEGIN_TF_DOCS budget -->
<!-- END_TF_DOCS budget -->
