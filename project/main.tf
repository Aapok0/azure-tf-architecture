# Local variables

locals {
  tags = {
    location    = "${var.location}"
    environment = "${var.environment}"
    project     = "${var.project}"
  }

  name_prefix = "${var.location_abbreviation[var.location]}-${var.environment}-${var.project}"
}

# Resource groups

resource "azurerm_resource_group" "project_rg" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = merge(var.tf_tags, local.tags)
}

# Virtual networks and their subnets

resource "azurerm_virtual_network" "project_vnet" {
  name                = "${local.name_prefix}-vnet"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name
  address_space       = var.virtual_network
  tags                = merge(var.tf_tags, local.tags)
}

resource "azurerm_subnet" "project_snet" {
  for_each             = var.subnets
  name                 = "${local.name_prefix}-snet"
  resource_group_name  = azurerm_resource_group.project_rg.name
  virtual_network_name = azurerm_virtual_network.project_vnet.name
  address_prefixes     = each.value
}
