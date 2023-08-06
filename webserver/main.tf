locals {
  tags = {
    location = {
      key   = "location"
      value = "${var.location}"
    }
    environment = {
      key   = "environment"
      value = "${var.environment}"
    }
    project = {
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

  subnet {
    name           = "subnet2"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.webserver_nsg.id
  }

  tags = var.tf_tags
}
