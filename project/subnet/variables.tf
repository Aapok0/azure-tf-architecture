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
  type        = list
  description = "List of cidr ranges for the subnet."
}

variable "nsg_rules" {
  type        = any
  description = "Map of rules for the subnet's security group."
}

variable "tags" {
  type        = map(string)
  description = "Tags to be added to all resources in the module."
}
