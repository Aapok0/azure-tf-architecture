variable "contact_email" {
  type        = string
  description = "Email contacted, when alerts are triggered."
}

variable "tags" {
  type        = map(string)
  description = "Tags to be added to all resources."
  default = {
    source = "terraform"
    owner  = "Aapo Kokko"
  }
}

variable "location" {
  type        = string
  description = "Default location of resources."
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
  description = "Abbreviation of the default location of resources."
  default = {
    northeurope   = "ne"
    norwayeast    = "nwe"
    swedencentral = "sdc"
    westeurope    = "we"
  }
}
