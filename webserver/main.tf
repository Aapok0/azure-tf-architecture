locals {
  tags = {
    location = {
      id    = "1"
      key   = "location"
      value = "${var.location}"
    }
    environment = {
      id    = "2"
      key   = "environment"
      value = "${var.environment}"
    }
    project = {
      id    = "3"
      key   = "project"
      value = "${var.project}"
    }
  }

  name_prefix = "${var.location_abbreviation[var.location]}-${var.environment}-${var.project}"
}

resource "azurerm_resource_group" "webserver_rg" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = var.tf_tags
}

resource "azurerm_network_security_group" "webserver_nsg" {
  name                = "${local.name_prefix}-nsg"
  location            = azurerm_resource_group.webserver_rg.location
  resource_group_name = azurerm_resource_group.webserver_rg.name
}

resource "azurerm_virtual_network" "webserver_vnet" {
  name                = "${local.name_prefix}-vnet"
  location            = azurerm_resource_group.webserver_rg.location
  resource_group_name = azurerm_resource_group.webserver_rg.name
  address_space       = ["10.0.0.0/26"]
  #dns_servers         = ["10.0.0.4", "10.0.0.5"]
  tags = var.tf_tags
}

resource "azurerm_subnet" "webserver_snet" {
  name                 = "${local.name_prefix}-snet"
  resource_group_name  = azurerm_resource_group.webserver_rg.name
  virtual_network_name = azurerm_virtual_network.webserver_vnet.name
  address_prefixes     = ["10.0.0.0/28"]
}
