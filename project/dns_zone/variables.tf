variable "name" {
  type        = string
  description = "Domain name to be used in the DNS zone."
}

variable "rg_name" {
  type        = string
  description = "Resource group name DNS zone is in."
}

variable "records" {
  type = map(object({
    ips = optional(list(string))
  }))
  description = "A records keyed by record name. ips overrides the target addresses; when omitted the record points at the project VM public IPs."
  default     = {}
}

variable "ttl" {
  type        = number
  description = "The Time To Live (TTL) of the DNS records in seconds."
  default     = 300
}

variable "vm_public_ips" {
  type        = list(string)
  description = "Public ips of the vms created in the project. Used as the default target for records without explicit ips."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to be added to all resources in the module."
}
