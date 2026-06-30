variable "name" {
  type        = string
  description = "Domain name to be used in the DNS zone."
}

variable "rg_name" {
  type        = string
  description = "Resource group name DNS zone is in."
}

variable "ttl" {
  type        = number
  description = "The Time To Live (TTL) of the DNS records in seconds."
  default     = 300
}

variable "a_records" {
  type        = map(list(string))
  description = "A records keyed by record name (@ for apex); value is the list of target IPs."
  default     = {}
}

variable "cname_records" {
  type        = map(string)
  description = "CNAME records keyed by record name; value is the alias target FQDN."
  default     = {}
}

variable "txt_records" {
  type        = map(list(string))
  description = "TXT records keyed by record name (e.g. asuid, asuid.www for Container Apps domain verification); value is the list of TXT values."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to be added to all resources in the module."
}
