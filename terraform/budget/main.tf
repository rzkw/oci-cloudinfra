resource "oci_budget_budget" "dollar_budget" {
  display_name   = "Free"
  amount         = 1
  reset_period   = "MONTHLY"
  compartment_id = var.tenancy_ocid
  target_type    = "COMPARTMENT"
  targets        = [var.tenancy_ocid]
}

resource "oci_budget_alert_rule" "forecast" {
  depends_on     = [oci_budget_budget.dollar_budget]
  budget_id      = oci_budget_budget.dollar_budget.id
  type           = "FORECAST"
  threshold      = 1
  threshold_type = "PERCENTAGE"
  recipients     = var.budget_alert_email
}

resource "oci_budget_alert_rule" "actual" {
  depends_on     = [oci_budget_budget.dollar_budget]
  budget_id      = oci_budget_budget.dollar_budget.id
  type           = "ACTUAL"
  threshold      = 1
  threshold_type = "PERCENTAGE"
  recipients     = var.budget_alert_email
}
