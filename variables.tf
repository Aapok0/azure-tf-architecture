variable "contact_emails" { # Sensitive information -> define in a tfvars file
  type        = list(any)
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
  type        = map(any)
  description = "Tags that are required in resources."
  default = {
    owner = {
      id  = "own"
      key = "owner"
    }
  }
}

variable "required_rg_tags" {
  type        = map(any)
  description = "Tags that are required in resource groups."
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
  type        = map(any)
  description = "Tags that are inherited by resources from resource groups."
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
  type          = any
  description   = "Map that holds all the variables required for the project to create resource group, networks, security groups and vms."
}
