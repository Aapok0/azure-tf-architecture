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
  type        = map(any)
  description = "Tags that are required in resources."
}

variable "required_rg_tags" {
  type        = map(any)
  description = "Tags that are required in resource groups."
}

variable "inherited_tags" {
  type        = map(any)
  description = "Tags that are inherited by resources from resource groups."
}
