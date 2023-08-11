# Already existing data from Azure

data "azurerm_subscription" "current" {}

# General resources

module "sub_budget" {
  source          = "./general/budget"

  scope           = "sub"
  id              = data.azurerm_subscription.current.id
  name            = "${data.azurerm_subscription.current.display_name}-budget"

  amount          = 10
  time_grain      = "Monthly"
  start_date      = "2023-08-01T00:00:00Z"
  end_date        = "2025-08-01T00:00:00Z"

  threshold_alert = true
  threshold       = 75.0
  forecast_alert  = true

  contact_emails  = var.contact_emails
  contact_roles   = ["Owner"]
}

# Projects

module "homepage_prd" {
  source = "./project"

  # General settings
  location    = "swedencentral"
  environment = "prd"
  project     = "homepage"

  # Access to virtual machines
  ssh_addr_prefixes = var.ssh_addr_prefixes
  admin_user        = var.admin_user

  # Data disk
  data_disk      = false
  data_disk_size = 0 # GB

  # Tags for everything in this architecture deployed with Terraform
  tf_tags = var.tf_tags
}
