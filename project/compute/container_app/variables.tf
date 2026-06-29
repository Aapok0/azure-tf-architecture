variable "name" {
  type        = string
  description = "Base name of the Container App. The environment is named <name>-env."
}

variable "location" {
  type        = string
  description = "Azure region the resources are located in."
}

variable "rg_name" {
  type        = string
  description = "Name of the resource group the resources are added to."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for environment logs. Null disables log collection."
  default     = null
}

variable "details" {
  description = "Container App definition: containers, scaling and ingress settings."
  type = object({
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
  })
}

variable "tags" {
  type        = map(string)
  description = "Tags to be added to all resources in the module."
}
