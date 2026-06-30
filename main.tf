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
  start_date = "2026-06-01T00:00:00Z" # first day of current month when extending end_date
  end_date   = "2027-12-01T00:00:00Z"

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

## Log Analytics - shared workspace
module "log_analytics" {
  source = "./general/log_analytics"

  count = var.log_analytics_enabled ? 1 : 0

  # Name and location
  name     = "${var.location_abbreviation[var.location]}-law"
  location = var.location

  # Cap daily ingestion so a 31-day month stays under 5 GB (0.16 * 31 = 4.96).
  # Bump this if logging hits quota consistently.
  daily_quota_gb = 0.16

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
  location    = each.value.location
  environment = each.value.environment
  project     = each.key

  # Virtual network
  vnet    = each.value.vnet
  subnets = each.value.subnets

  # Admin source IPs injected into NSG rules flagged admin_restricted
  admin_allowed_ips = var.admin_allowed_ips

  # Compute resources
  vms            = each.value.vms
  container_apps = each.value.container_apps

  # Shared Log Analytics workspace (compute resources opt in per-resource)
  log_analytics_workspace_id = var.log_analytics_enabled ? module.log_analytics[0].workspace_id_out : null

  # DNS
  domains = each.value.domains

  # Key Vault for VM credentials
  key_vault_enabled = each.value.key_vault_enabled
  tenant_id         = data.azurerm_client_config.current.tenant_id
  admin_object_id   = data.azurerm_client_config.current.object_id

  # Tags for everything in this architecture deployed with Terraform
  tf_tags = var.tf_tags
}
