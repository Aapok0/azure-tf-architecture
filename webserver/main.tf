resource "azurerm_resource_group" "webserver_rg" {
  name     = "${var.location_abbreviation[var.location]}-${var.environment}-${var.project}-rg"
  location = var.location
  tags     = var.tags
}
