# Subscription scoped resources

module "budget" {
  source = "./general/budget"

  scope    = "sub"
  scope_id = data.azurerm_subscription.current.id
  name     = "${data.azurerm_subscription.current.display_name}-budget"

  amount     = 10
  time_grain = "Monthly"
  start_date = "2026-06-01T00:00:00Z" # first day of current month when extending end_date
  end_date   = "2027-12-01T00:00:00Z"

  threshold_alert = true
  threshold       = 75.0
  forecast_alert  = true
  contact_emails  = var.contact_emails
  contact_roles   = ["Owner"]
}

module "nwatcher" {
  source = "./general/network_watcher"

  name     = "${var.location_abbreviation[var.location]}-nwatcher"
  location = var.location
  tf_tags  = var.tf_tags
}

module "log_analytics" {
  source = "./general/log_analytics"

  count = var.log_analytics_enabled ? 1 : 0

  name     = "${var.location_abbreviation[var.location]}-law"
  location = var.location

  # Cap daily ingestion so a 31-day month stays under 5 GB (0.16 * 31 = 4.96).
  daily_quota_gb = 0.16

  tf_tags = var.tf_tags
}

module "sub_allowed_locations" {
  source = "./policy/location"

  scope         = "sub"
  scope_id      = data.azurerm_subscription.current.id
  scope_name    = data.azurerm_subscription.current.display_name
  location_list = var.location_list
}

module "sub_tags" {
  source = "./policy/tags"

  scope            = "sub"
  scope_id         = data.azurerm_subscription.current.id
  scope_name       = data.azurerm_subscription.current.display_name
  location         = var.location
  required_tags    = var.required_tags
  required_rg_tags = var.required_rg_tags
  inherited_tags   = var.inherited_tags
}

module "vm_sku" {
  source = "./policy/vm_sku"

  scope      = "sub"
  scope_id   = data.azurerm_subscription.current.id
  scope_name = data.azurerm_subscription.current.display_name
  sku_list   = var.sku_list
}

# Projects

module "project" {
  source = "./project"

  for_each = var.projects

  location    = each.value.location
  environment = each.value.environment
  project     = each.key

  vnet              = each.value.vnet
  subnets           = each.value.subnets
  admin_allowed_ips = var.admin_allowed_ips

  vms                        = each.value.vms
  container_apps             = each.value.container_apps
  log_analytics_workspace_id = var.log_analytics_enabled ? module.log_analytics[0].workspace_id_out : null

  domains = each.value.domains

  key_vault_enabled = each.value.key_vault_enabled
  tenant_id         = data.azurerm_client_config.current.tenant_id
  admin_object_id   = data.azurerm_client_config.current.object_id

  tf_tags = var.tf_tags
}
