# Network watcher module: a per-region network watcher in its own resource
# group, tagged as shared (environment/project = all) since it serves every
# project in the region.

resource "azurerm_resource_group" "nwatcher_rg" {
  name     = "${var.name}-rg"
  location = var.location
  tags = merge(var.tf_tags, {
    location    = var.location
    environment = "all"
    project     = "all"
  })
}

resource "azurerm_network_watcher" "nwatcher" {
  name                = var.name
  location            = var.location
  resource_group_name = azurerm_resource_group.nwatcher_rg.name
  tags = merge(var.tf_tags, {
    location    = var.location
    environment = "all"
    project     = "all"
    service     = "network watcher"
  })
}
