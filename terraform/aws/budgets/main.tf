resource "aws_budgets_budget" "zero-spend" {
    name = "zero-spend"
    budget_type = "COST"
    time_unit = "MONTHLY"

}

resource "aws_budgets_budget" "monthly-budget" {
    name = "monthly-budget"
    budget_type = "COST"
    time_unit = "MONTHLY"

    notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["hello@walk-llc.com"]
    }

}