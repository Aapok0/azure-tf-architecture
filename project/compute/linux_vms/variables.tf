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

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID forwarded to each VM. Null disables log collection."
  default     = null
}

variable "details" {
  description = "Virtual machine details forwarded to the linux_vm module. count controls how many identical VMs are created; the rest configure size, access, public IP, optional data disk and a pinned OS image."
  type = object({
    count                     = optional(number, 1)
    sku                       = optional(string, "Standard_B1ls")
    admin_ssh_public_key_path = optional(string, "~/.ssh/id_rsa.pub")
    public_ip                 = optional(bool, false)
    ip_allocation             = optional(string, "Static")
    public_ip_sku             = optional(string, "Standard")
    data_disk                 = optional(bool, false)
    data_disk_size            = optional(number, 0)
    os_image = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    }))
  })
}

variable "tags" {
  type        = map(string)
  description = "Tags to be added to all resources in the module."
}
