# Sweden Central

resource "azurerm_resource_group" "nwatcher_rg" {
  name     = "${var.location_abbreviation[var.location]}-nwatcher-rg"
  location = var.location
  tags = merge(var.tf_tags, {
    location    = "${var.location}"
    environment = "all"
    project     = "all"
  })
}

resource "azurerm_network_watcher" "nwatcher" {
  name                = "${var.location_abbreviation[var.location]}-nwatcher"
  location            = azurerm_resource_group.nwatcher_rg.location
  resource_group_name = azurerm_resource_group.nwatcher_rg.name
  tags = merge(var.tf_tags, {
    location = "${var.location}"
    service  = "network watcher"
  })
}
