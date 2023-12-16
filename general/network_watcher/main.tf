# Resource group to hold the network watcher

resource "azurerm_resource_group" "nwatcher_rg" {
  name     = "${var.name}-rg"
  location = var.location
  tags = merge(var.tf_tags, {
    location    = "${var.location}"
    environment = "all"
    project     = "all"
  })
}

# Network watcher (restricted to region)

resource "azurerm_network_watcher" "nwatcher" {
  name                = var.name
  location            = var.location
  resource_group_name = azurerm_resource_group.nwatcher_rg.name
  tags = merge(var.tf_tags, {
    location    = "${var.location}"
    environment = "all"
    project     = "all"
    service     = "network watcher"
  })
}
