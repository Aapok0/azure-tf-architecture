variable "location" {
  type        = string
  description = "Azure region resource group or resource is located in."
  default     = "swedencentral"

  validation {
    condition = contains(
      ["northeurope", "norwayeast", "swedencentral", "westeurope"],
      var.location
    )
    error_message = "Allowed locations are northeurope, norwayeast, swedencentral and westeurope."
  }
}

variable "location_abbreviation" {
  type        = map(string)
  description = "Abbreviation of the Azure region."
  default = {
    northeurope   = "ne"
    norwayeast    = "nwe"
    swedencentral = "sdc"
    westeurope    = "we"
  }
}

variable "environment" {
  type        = string
  description = "Environment for the deployed resources: dev, tst or prd."

  validation {
    condition = contains(
      ["dev", "tst", "prd"],
      var.environment
    )
    error_message = "Allowed environments are dev, tst and prd."
  }
}

variable "project" {
  type        = string
  description = "Name of the project webserver is created for."
}

variable "vnet" {
  type        = list(any)
  description = "List of address spaces that are used in the virtual network in CIDR."
}

variable "subnets" {
  type        = any
  description = "Map of CIDR address prefixes and security rules that are used in each subnet and it's securitu group."
}

variable "admin_allowed_ips" {
  type        = list(string)
  description = "Admin source IPs injected into NSG rules flagged admin_restricted = true."
  default     = []
}

variable "vms" {
  type        = any
  description = "Map of VMs and variables needed to create them."
}

variable "container_apps" {
  type        = any
  description = "Map of Container Apps and the settings needed to create them."
  default     = {}
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Shared Log Analytics workspace ID. Compute resources opt in per-resource via their own log_analytics flag."
  default     = null
}

variable "domains" {
  type        = any
  description = "Map of names of the project's domains, the records needed and additional settings. Used to create a DNS zone and records."
}

variable "tf_tags" {
  type        = map(string)
  description = "Default tags to be added to all resource groups and resources."
}

variable "key_vault_enabled" {
  type        = bool
  description = "Whether to create a Key Vault for this project and store VM credentials in it."
  default     = true
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID for the Key Vault."
}

variable "admin_object_id" {
  type        = string
  description = "Object ID of the principal granted Key Vault Administrator (data-plane) access."
}
