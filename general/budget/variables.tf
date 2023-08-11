variable "scope" {
  type        = string
  description = "Budget's scope: resource group (rg), subscription (sub) or management group (mg)."

  validation {
    condition = contains(
      ["rg", "sub", "mg"],
      var.scope
    )
    error_message = "Allowed scopes are resource group (rg), subscription (sub) or management group (mg). Use the abbreviation in the scope."
  }
}

variable "id" {
  type        = string
  description = "ID for the chose scope of the budget."
}

variable "name" {
  type        = string
  description = "Name of the budget."
}

variable "amount" {
  type        = number
  description = "Budget limit in dollars."
}

variable "time_grain" {
  type        = string
  description = "Time frame budget limit is tracked in: BillingAnnual, BillingMonth, BillingQuarter, Annually, Monthly and Quarterly."

  validation {
    condition = contains(
      ["BillingAnnual", "BillingMonth", "BillingQuarter", "Annually", "Monthly", "Quarterly"],
      var.time_grain
    )
    error_message = "Allowed time grains are BillingAnnual, BillingMonth, BillingQuarter, Annually, Monthly and Quarterly."
  }
}

variable "start_date" {
  type        = string
  description = "Starting date of the budget monitoring period in format: YYYY-MM-01T00:00:00Z"
}

variable "end_date" {
  type        = string
  description = "Ending date of the budget monitoring period in format: YYYY-MM-01T00:00:00Z"
}

variable "threshold_alert" {
  type        = bool
  description = "Whether threshold alert is enabled: true or false. Budget is above a percentage threshold."
}

variable "threshold" {
  type        = number
  description = "Threshold for notification in percentage of the budget limit with one decimal accuracy."
}

variable "forecast_alert" {
  type        = bool
  description = "Whether forecast alert is enabled: true or false. Budget is forecasted to go over the limit."
}

variable "contact_emails" {
  type        = list(any)
  description = "Emails that are notified."
}

variable "contact_roles" {
  type        = list(any)
  description = "Roles that are notified."
}
