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
  type        = list(string)
  description = "List of address spaces that are used in the virtual network in CIDR."
}

variable "subnets" {
  description = "Subnets keyed by name, each with its CIDR ranges and optional NSG rules."
  type = map(object({
    cidr = list(string)
    nsg_rules = optional(map(object({
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
    })), {})
  }))
}

variable "admin_allowed_ips" {
  type        = list(string)
  description = "Admin source IPs injected into NSG rules flagged admin_restricted = true."
  default     = []
}

variable "vms" {
  description = "VMs keyed by name. subnet selects the target subnet, log_analytics opts the VM into the shared workspace, service_tags are merged into the VM's tags; the rest are forwarded to the linux_vm module."
  type = map(object({
    count                     = optional(number, 1)
    sku                       = optional(string, "Standard_B1ls")
    subnet                    = optional(string, "default")
    public_ip                 = optional(bool, false)
    ip_allocation             = optional(string, "Static")
    public_ip_sku             = optional(string, "Standard")
    admin_ssh_public_key_path = optional(string, "~/.ssh/id_rsa.pub")
    data_disk                 = optional(bool, false)
    data_disk_size            = optional(number, 0)
    os_image = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    }))
    log_analytics = optional(bool, false)
    service_tags  = optional(map(string), {})
  }))
  default = {}
}

variable "container_apps" {
  description = "Container Apps keyed by name. log_analytics opts the environment into the shared workspace, service_tags are merged into the app's tags; the rest define the app's containers, scaling and ingress."
  type = map(object({
    containers = list(object({
      name   = string
      image  = string
      cpu    = optional(number, 0.25)
      memory = optional(string, "0.5Gi")
      env = optional(list(object({
        name  = string
        value = string
      })), [])
    }))
    revision_mode       = optional(string, "Single")
    min_replicas        = optional(number, 0)
    max_replicas        = optional(number, 1)
    ingress_external    = optional(bool, true)
    ingress_target_port = optional(number, 8080)
    log_analytics       = optional(bool, false)
    service_tags        = optional(map(string), {})
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Shared Log Analytics workspace ID. Compute resources opt in per-resource via their own log_analytics flag."
  default     = null
}

variable "domains" {
  description = "Domains keyed by zone name. Each creates a DNS zone with A records; a record's ips default to the project VM public IPs when omitted."
  type = map(object({
    ttl = optional(number, 300)
    records = optional(map(object({
      ips = optional(list(string))
    })), {})
  }))
  default = {}
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
