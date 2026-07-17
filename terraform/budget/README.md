## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | ~> 8.20 |

## Resources

| Name | Type |
| ---- | ---- |
| [oci_budget_alert_rule.actual](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/budget_alert_rule) | resource |
| [oci_budget_alert_rule.forecast](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/budget_alert_rule) | resource |
| [oci_budget_budget.dollar_budget](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/budget_budget) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_budget_alert_email"></a> [budget\_alert\_email](#input\_budget\_alert\_email) | Email address for budget alerts | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | OCI region | `string` | `"ap-melbourne-1"` | no |
| <a name="input_tenancy_ocid"></a> [tenancy\_ocid](#input\_tenancy\_ocid) | OCID of the tenancy | `string` | n/a | yes |

## Outputs

No outputs.
