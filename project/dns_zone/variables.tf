variable "name" {
  type        = string
  description = "Domain name to be used in the DNS zone."
}

variable "rg_name" {
  type        = string
  description = "Resource group name DNS zone is in."
}

variable "records" {
  type        = any
  description = "Map of records and optionally their ips and ttl values."
}

variable "ttl" {
  type        = number
  description = "The Time To Live (TTL) of the DNS records in seconds."
}

variable "vm_public_ips" {
  type        = any
  description = "Public ips of the vms created in the project."
}

variable "tags" {
  type        = map(string)
  description = "Tags to be added to all resources in the module."
}
