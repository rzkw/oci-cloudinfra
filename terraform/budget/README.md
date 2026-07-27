# Budget

Monthly cost alert — $1 budget with email notifications at 1% threshold.

## Resources

| Name | Description |
|------|-------------|
| `oci_budget_budget.dollar_budget` | $1/month budget |
| `oci_budget_alert_rule.actual` | Alert on actual spend |
| `oci_budget_alert_rule.forecast` | Alert on forecasted spend |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `tenancy_ocid` | Tenancy OCID | `string` | n/a |
| `budget_alert_email` | Email for budget alerts | `string` | n/a |
| `region` | OCI region | `string` | `"ap-melbourne-1"` |

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
