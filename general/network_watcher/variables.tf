variable "name" {
  type        = string
  description = "Name of the network watcher."
}

variable "location" {
  type        = string
  description = "Azure region resource group or resource is located in."
}

variable "tf_tags" {
  type        = map(string)
  description = "Default tags to be added to all resource groups and resources deployed from terraform."
}
