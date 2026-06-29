variable "name" {
  type        = string
  description = "Name of the Log Analytics workspace."
}

variable "location" {
  type        = string
  description = "Azure region resource group or resource is located in."
}

variable "sku" {
  type        = string
  description = "Workspace pricing SKU."
  default     = "PerGB2018"
}

variable "retention_in_days" {
  type        = number
  description = "Number of days ingested data is retained."
  default     = 30
}

variable "daily_quota_gb" {
  type        = number
  description = "Daily ingestion cap in GB. -1 means unlimited."
  default     = -1
}

variable "tf_tags" {
  type        = map(string)
  description = "Default tags to be added to all resource groups and resources deployed from terraform."
}
