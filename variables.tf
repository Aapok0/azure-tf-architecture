variable "contact_email" {
  type        = string
  description = "Email contacted, when alerts are triggered."
}

variable "tf_tags" {
  type        = map(string)
  description = "Default tags to be added to all resource groups and resources."
  default = {
    source = "terraform"
    owner  = "Aapo Kokko"
  }
}

variable "inherited_rg_tags" {
  type        = map(any)
  description = "Tags that will always be inherited from resource groups."
  default = {
    location = {
      id  = "1"
      key = "location"
    }
    environment = {
      id  = "2"
      key = "environment"
    }
    project = {
      id  = "3"
      key = "project"
    }
  }
}

variable "location_list" {
  type        = string
  description = "List of allowed locations."
  default     = "[\"northeurope\",\"norwayeast\",\"swedencentral\",\"westeurope\"]"
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
