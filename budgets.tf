resource "azurerm_consumption_budget_subscription" "budget" {
  name            = "${data.azurerm_subscription.current.display_name}-budget"
  subscription_id = data.azurerm_subscription.current.id

  amount     = 10
  time_grain = "Monthly"

  time_period {
    start_date = "2023-08-01T00:00:00Z"
    end_date   = "2025-08-01T00:00:00Z"
  }

  notification {
    enabled   = true
    threshold = 80.0
    operator  = "EqualTo"

    contact_emails = [var.contact_email]

    contact_roles = ["Owner"]
  }

  notification {
    enabled        = true
    threshold      = 100.0
    operator       = "GreaterThan"
    threshold_type = "Forecasted"

    contact_emails = [var.contact_email]

    contact_roles = ["Owner"]
  }
}
