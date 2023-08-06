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

resource "azurerm_resource_group" "webserver_rg" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = merge(var.tf_tags, local.tags)
}

# Network security groups

resource "azurerm_network_security_group" "webserver_nsg" {
  name                = "${local.name_prefix}-nsg"
  location            = azurerm_resource_group.webserver_rg.location
  resource_group_name = azurerm_resource_group.webserver_rg.name
  tags                = merge(var.tf_tags, local.tags)
}

# Virtual networks and their subnets

resource "azurerm_virtual_network" "webserver_vnet" {
  name                = "${local.name_prefix}-vnet"
  location            = azurerm_resource_group.webserver_rg.location
  resource_group_name = azurerm_resource_group.webserver_rg.name
  address_space       = ["10.0.0.0/26"]
  tags                = merge(var.tf_tags, local.tags)
}

resource "azurerm_subnet" "webserver_snet" {
  name                 = "${local.name_prefix}-snet"
  resource_group_name  = azurerm_resource_group.webserver_rg.name
  virtual_network_name = azurerm_virtual_network.webserver_vnet.name
  address_prefixes     = ["10.0.0.0/28"]
}
