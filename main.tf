# Already existing data from Azure

data "azurerm_subscription" "current" {}

# Modules

module "webserver_homepage_prd" {
  source = "./webserver"

  # General settings
  location    = "swedencentral"
  environment = "prd"
  project     = "homepage"

  # Access to virtual machines
  ssh_addr_prefixes = var.ssh_addr_prefixes
  admin_user        = var.admin_user

  # Tags for everything in this architecture deployed with Terraform
  tf_tags = var.tf_tags
}
