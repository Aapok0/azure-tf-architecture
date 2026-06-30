# Log Analytics module: one shared workspace (in its own resource group) that
# compute resources across projects send logs to. daily_quota_gb caps ingestion
# to keep the workspace within the free tier / a fixed monthly budget.

# Resource group to hold the shared Log Analytics workspace

resource "azurerm_resource_group" "law_rg" {
  name     = "${var.name}-rg"
  location = var.location
  tags = merge(var.tf_tags, {
    location    = var.location
    environment = "all"
    project     = "all"
  })
}

# Shared Log Analytics workspace consumed across projects (Container Apps, VMs)

resource "azurerm_log_analytics_workspace" "law" {
  name                = var.name
  location            = var.location
  resource_group_name = azurerm_resource_group.law_rg.name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb
  tags = merge(var.tf_tags, {
    location    = var.location
    environment = "all"
    project     = "all"
    service     = "log analytics"
  })
}
