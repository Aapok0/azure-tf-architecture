variable "name_prefix" {
  type        = string
  description = "Name prefix for all resources in the module."
}

variable "location" {
  type        = string
  description = "Azure region resource group or resource is located in."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name virtual machine is in."
}

variable "subnet_id" {
  type        = string
  description = "ID of the virtual machine's subnet."
}

variable "vm_sku" {
  type        = string
  description = "Size of the virtual machine: Standard_B1ls, Standard_B1s or Standard_B1ms."
  default     = "Standard_B1ls"

  validation {
    condition = contains(
      ["Standard_B1ls", "Standard_B1s", "Standard_B1ms"],
      var.vm_sku
    )
    error_message = "Allowed virtual machine SKUs are Standard_B1ls, Standard_B1s and Standard_B1ms."
  }
}

variable "admin_user" { # Sensitive information -> define name in a tfvars file
  type        = string
  description = "Username for the root user in the virtual machine."
}

variable "ssh_addr_prefixes" { # Sensitive information -> define in a tfvars file
  type        = list(any)
  description = "IP range for SSH access to the virtual machine."
}

variable "public_ip" {
  type        = bool
  description = "Whether a public ip is created for the virtual machine: true or false."
}

variable "allocation_method" {
  type        = string
  description = "Public IP's allocation method: Static or Dynamic."

  validation {
    condition = contains(
      ["Static", "Dynamic"],
      var.allocation_method
    )
    error_message = "Allowed allocation methods are Static and Dynamic."
  }
}

variable "data_disk" {
  type        = bool
  description = "Whether a data disk is created for virtual machine or not: true or false."
}

variable "data_disk_size" {
  type        = number
  description = "Size of data disk in gigabytes."
}

variable "tags" {
  type        = map(string)
  description = "Tags to be added to all resources in the module."
}
