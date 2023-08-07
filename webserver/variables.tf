variable "tf_tags" {
  type        = map(string)
  description = "Default tags to be added to all resource groups and resources."
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

variable "environment" {
  type        = string
  description = "Environment for the deployed resources: dev, tst or prd."

  validation {
    condition = contains(
      ["dev", "tst", "prd"],
      var.environment
    )
    error_message = "Allowed locations are northeurope, norwayeast, swedencentral and westeurope."
  }
}

variable "project" {
  type        = string
  description = "Name of the project webserver is created for."
}

variable "vm_sku" {
  type        = string
  description = "Size of the virtual machine."
  default     = "Standard_B1ls"

  validation {
    condition = contains(
      ["Standard_B1ls", "Standard_B1s", "Standard_B1ms"],
      var.vm_sku
    )
    error_message = "Allowed virtual machine SKUs are Standard_B1ls, Standard_B1s and Standard_B1ms."
  }
}

variable "admin" { # Sensitive information -> define real name in a tfvars file
  type        = string
  description = "Username for the root user in a virtual machine."
  default     = "azureadmin"
}
