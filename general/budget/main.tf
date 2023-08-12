# Resource group scope

## Budget with notifications
resource "azurerm_consumption_budget_resource_group" "rg_budget" {
  count             = var.scope == "rg" ? 1 : 0
  name              = var.name
  resource_group_id = var.scope_id
  amount            = var.amount
  time_grain        = var.time_grain

  time_period {
    start_date = var.start_date
    end_date   = var.end_date
  }

  notification {
    enabled   = var.threshold_alert
    threshold = var.threshold
    operator  = "EqualTo"

    contact_emails = var.contact_emails
    contact_roles  = var.contact_roles
  }

  notification {
    enabled        = var.forecast_alert
    threshold      = 100.0
    operator       = "GreaterThan"
    threshold_type = "Forecasted"

    contact_emails = var.contact_emails
    contact_roles  = var.contact_roles
  }
}

# Subscription scope

## Budget with notifications
resource "azurerm_consumption_budget_subscription" "sub_budget" {
  count           = var.scope == "sub" ? 1 : 0
  name            = var.name
  subscription_id = var.scope_id
  amount          = var.amount
  time_grain      = var.time_grain

  time_period {
    start_date = var.start_date
    end_date   = var.end_date
  }

  notification {
    enabled   = var.threshold_alert
    threshold = var.threshold
    operator  = "EqualTo"

    contact_emails = var.contact_emails
    contact_roles  = var.contact_roles
  }

  notification {
    enabled        = var.forecast_alert
    threshold      = 100.0
    operator       = "GreaterThan"
    threshold_type = "Forecasted"

    contact_emails = var.contact_emails
    contact_roles  = var.contact_roles
  }
}

# Management group scope

## Budget with notifications
resource "azurerm_consumption_budget_management_group" "mg_budget" {
  count               = var.scope == "mg" ? 1 : 0
  name                = var.name
  management_group_id = var.scope_id
  amount              = var.amount
  time_grain          = var.time_grain

  time_period {
    start_date = var.start_date
    end_date   = var.end_date
  }

  notification {
    enabled   = var.threshold_alert
    threshold = var.threshold
    operator  = "EqualTo"

    contact_emails = var.contact_emails
  }

  notification {
    enabled        = var.forecast_alert
    threshold      = 100.0
    operator       = "GreaterThan"
    threshold_type = "Forecasted"

    contact_emails = var.contact_emails
  }
}
