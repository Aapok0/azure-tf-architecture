variable "scope" {
  type        = string
  description = "Policy's scope: resource group (rg) or subscription (sub)."

  validation {
    condition = contains(
      ["rg", "sub"],
      var.scope
    )
    error_message = "Allowed scopes are resource group (rg) or subscription (sub). Use the abbreviation in the scope."
  }
}

variable "scope_id" {
  type        = string
  description = "ID for the chosen scope of the policy."
}

variable "scope_name" {
  type        = string
  description = "Name of the chosen scope of the policy."
}

variable "sku_list" {
  type        = string
  description = "List of allowed vm skus."
}
