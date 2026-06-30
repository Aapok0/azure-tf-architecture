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

variable "location" {
  type        = string
  description = "Location of the inherited tags policy."
}

variable "required_tags" {
  type = map(object({
    id  = string
    key = string
  }))
  description = "Tags that are required in resources. Keyed by tag name; id is the policy assignment suffix, key is the tag's name."
}

variable "required_rg_tags" {
  type = map(object({
    id  = string
    key = string
  }))
  description = "Tags that are required in resource groups. Keyed by tag name; id is the policy assignment suffix, key is the tag's name."
}

variable "inherited_tags" {
  type = map(object({
    id  = string
    key = string
  }))
  description = "Tags that are inherited by resources from resource groups. Keyed by tag name; id is the policy assignment suffix, key is the tag's name."
}
