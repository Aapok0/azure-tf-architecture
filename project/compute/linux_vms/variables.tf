variable "name" {
  type        = string
  description = "Name prefix for all resources in the module."
}

variable "location" {
  type        = string
  description = "Azure region resource group or resource is located in."
}

variable "rg_name" {
  type        = string
  description = "Resource group name virtual machine is in."
}

variable "subnet_id" {
  type        = string
  description = "ID of the virtual machine's subnet."
}

variable "details" {
  type        = any
  description = "Map of virtual machine details needed to create them."
}

variable "tags" {
  type        = map(string)
  description = "Tags to be added to all resources in the module."
}
