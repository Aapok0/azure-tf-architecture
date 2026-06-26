variable "name" {
  type        = string
  description = "Key Vault name (3-24 chars, globally unique, alphanumeric and dashes)."
}

variable "location" {
  type        = string
  description = "Azure region the Key Vault is located in."
}

variable "rg_name" {
  type        = string
  description = "Resource group name the Key Vault is in."
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID the Key Vault belongs to."
}

variable "admin_object_id" {
  type        = string
  description = "Object ID of the principal granted Key Vault Administrator (data-plane) access."
}

variable "secrets" {
  type        = map(string)
  description = "Map of secret name to value to store in the Key Vault."
  default     = {}
  sensitive   = true
}

variable "sku" {
  type        = string
  description = "Key Vault SKU: standard or premium."
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku)
    error_message = "Key Vault SKU must be standard or premium."
  }
}

variable "purge_protection" {
  type        = bool
  description = "Enable purge protection. Leave false while rebuilding so the vault can be fully deleted/recreated."
  default     = false
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Days a soft-deleted vault/secret is recoverable (7-90)."
  default     = 7
}

variable "tags" {
  type        = map(string)
  description = "Tags to be added to all resources in the module."
}
