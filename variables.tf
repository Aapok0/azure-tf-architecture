variable "contact_emails" { # Sensitive information -> define in a tfvars file
  type        = list(string)
  description = "Emails contacted, when alerts are triggered."
}

variable "tf_tags" {
  type        = map(string)
  description = "Default tags to be added to all resource groups and resources deployed from terraform."
  default = {
    source = "terraform"
    owner  = "Aapo Kokko"
  }
}

variable "required_tags" {
  type = map(object({
    id  = string
    key = string
  }))
  description = "Tags that are required in resources. Keyed by tag name; id is the policy assignment suffix, key is the tag's name."
  default = {
    owner = {
      id  = "own"
      key = "owner"
    }
  }
}

variable "required_rg_tags" {
  type = map(object({
    id  = string
    key = string
  }))
  description = "Tags that are required in resource groups. Keyed by tag name; id is the policy assignment suffix, key is the tag's name."
  default = {
    owner = {
      id  = "own"
      key = "owner"
    }
    location = {
      id  = "loc"
      key = "location"
    }
    environment = {
      id  = "env"
      key = "environment"
    }
    project = {
      id  = "pro"
      key = "project"
    }
  }
}

variable "inherited_tags" {
  type = map(object({
    id  = string
    key = string
  }))
  description = "Tags that are inherited by resources from resource groups. Keyed by tag name; id is the policy assignment suffix, key is the tag's name."
  default = {
    location = {
      id  = "loc"
      key = "location"
    }
    environment = {
      id  = "env"
      key = "environment"
    }
    project = {
      id  = "pro"
      key = "project"
    }
  }
}

variable "location_list" {
  type        = string
  description = "List of allowed Azure regions."
  default     = "[\"northeurope\", \"norwayeast\", \"swedencentral\", \"westeurope\"]"
}

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

variable "sku_list" {
  type        = string
  description = "List of allowed vm skus."
  default     = "[\"Standard_B1ls\", \"Standard_B1s\", \"Standard_B1ms\", \"Standard_B2s\"]"
}

variable "projects" {
  description = "Projects to deploy, keyed by project name. Each project gets a resource group, virtual network with subnets/NSGs, optional VMs and Container Apps, DNS zones and a Key Vault."
  type = map(object({
    location          = optional(string, "swedencentral")
    environment       = optional(string, "prd")
    key_vault_enabled = optional(bool, true)

    vnet = optional(list(string), ["10.0.0.0/26"])

    subnets = optional(map(object({
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
    })), { default = { cidr = ["10.0.0.0/28"] } })

    vms = optional(map(object({
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
    })), {})

    container_apps = optional(map(object({
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
    })), {})

    domains = optional(map(object({
      ttl = optional(number, 300)
      records = optional(map(object({
        ips = optional(list(string))
      })), {})
    })), {})
  }))
}

variable "admin_allowed_ips" {
  type        = list(string)
  description = "Single source of truth for admin (SSH/ICMP) source IPs. Applied to any NSG rule flagged admin_restricted = true, and synced to Ansible firewall_allowed_ips via scripts/sync-firewall-allowlist.sh."
  default     = []
}

variable "log_analytics_enabled" {
  type        = bool
  description = "Whether to create the shared subscription-level Log Analytics workspace. Compute resources reference it per-resource via their own log_analytics flag."
  default     = false
}
