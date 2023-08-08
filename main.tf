# Already existing data from Azure

data "azurerm_subscription" "current" {}

# Modules

module "webserver_homepage_prd" {
  source          = "./webserver"
  admin_user      = var.admin_user
  ssh_pubkey_path = var.ssh_pubkey_path
  tf_tags         = var.tf_tags
  location        = "swedencentral"
  environment     = "prd"
  project         = "homepage"
}
