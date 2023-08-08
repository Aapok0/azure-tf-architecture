variable "contact_email" { # Sensitive information -> define in a tfvars file
  type        = string
  description = "Email contacted, when alerts are triggered."
}

variable "admin_user" { # Sensitive information -> define in a tfvars file
  type        = string
  description = "Username for the root user in a virtual machine."
}

variable "ssh_pubkey_path" { # Sensitive information -> define in a tfvars file
  type        = string
  description = "Path to ssh public key to be uploaded to virtual machine for secure access."
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
  description = "Tags that are required everywhere."
  default = {
    owner = {
      id  = "own"
      key = "owner"
    }
  }
}

variable "required_rg_tags" {
  type        = map(any)
  description = "Tags that are required in resource groups and inherited by resources."
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
  description = "List of allowed locations."
  default     = "[\"northeurope\", \"norwayeast\", \"swedencentral\", \"westeurope\"]"
}

variable "location" {
  type        = string
  description = "Location of a resource."
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
  description = "Abbreviation of the location of a resource."
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
  default     = "[\"Standard_B1ls\", \"Standard_B1s\", \"Standard_B1ms\"]"
}
