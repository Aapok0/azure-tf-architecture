# Subscription scoped resources

## Budget - subscription
module "sub_budget" {
  source = "./general/budget"

  # Scope of the budget
  scope    = "sub"
  scope_id = data.azurerm_subscription.current.id
  name     = "${data.azurerm_subscription.current.display_name}-budget"

  # General settings
  amount     = 10
  time_grain = "Monthly"
  start_date = "2023-12-01T00:00:00Z"
  end_date   = "2025-12-01T00:00:00Z"

  # Notification settings
  threshold_alert = true
  threshold       = 75.0
  forecast_alert  = true
  contact_emails  = var.contact_emails
  contact_roles   = ["Owner"]
}

## Network watcher - Sweden Central
module "sdc_nwatcher" {
  source = "./general/network_watcher"

  # Name and location
  name     = "${var.location_abbreviation[var.location]}-nwatcher"
  location = var.location

  # Tags for everything in this architecture deployed with Terraform
  tf_tags = var.tf_tags
}

## Policies

### Allowed locations
module "sub_allowed_locations" {
  source = "./policy/location"

  # Scope of the policies
  scope      = "sub"
  scope_id   = data.azurerm_subscription.current.id
  scope_name = data.azurerm_subscription.current.display_name

  # Locations
  location_list = var.location_list
}

### Tags
module "sub_tags" {
  source = "./policy/tags"

  # Scope of the policies
  scope      = "sub"
  scope_id   = data.azurerm_subscription.current.id
  scope_name = data.azurerm_subscription.current.display_name
  location   = var.location

  # Required in all resources
  required_tags = var.required_tags

  # Required in all resource groups
  required_rg_tags = var.required_rg_tags

  # Inherited from resource groups
  inherited_tags = var.inherited_tags
}

### Virtual machine sizes
module "vm_sku" {
  source = "./policy/vm_sku"

  # Scope of the policies
  scope      = "sub"
  scope_id   = data.azurerm_subscription.current.id
  scope_name = data.azurerm_subscription.current.display_name

  # Sizes
  sku_list = var.sku_list
}

# Projects

## Homepage production

### Base resources
module "project" {
  source = "./project"

  for_each = var.projects

  # General settings
  location    = lookup(each.value, "location", "swedencentral")
  environment = lookup(each.value, "environment", "prd")
  project     = each.key

  # Virtual network
  vnet    = lookup(each.value, "vnet", ["10.0.0.0/26"])
  subnets = lookup(each.value, "subnets", { default = { cidr = ["10.0.0.0/28"] }})

  # Compute resources
  vms = lookup(each.value, "vms", {})

  # Tags for everything in this architecture deployed with Terraform
  tf_tags = var.tf_tags
}
