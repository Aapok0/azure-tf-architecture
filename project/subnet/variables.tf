variable "name" {
  type        = string
  description = "Name of the subnet."
}

variable "location" {
  type        = string
  description = "Azure region resource group or resource is located in."
}

variable "rg_name" {
  type        = string
  description = "Name of the resource group subnet is added to."
}

variable "vnet_name" {
  type        = string
  description = "Name of the virtual network subnet is added to."
}

variable "cidr" {
  type        = list(string)
  description = "List of cidr ranges for the subnet."
}

variable "nsg_rules" {
  description = "NSG rules keyed by name. admin_restricted swaps the source for the central admin_allowed_ips list; the source/destination address and port fields map directly to azurerm_network_security_rule (singular or plural variants)."
  type = map(object({
    name                         = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    admin_restricted             = optional(bool, false)
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    source_port_range            = optional(string)
    source_port_ranges           = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
  }))
  default = {}
}

variable "admin_allowed_ips" {
  type        = list(string)
  description = "Admin source IPs injected into rules flagged admin_restricted = true (single source of truth for the SSH/ICMP allowlist)."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to be added to all resources in the module."
}
