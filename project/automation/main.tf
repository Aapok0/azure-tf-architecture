# Automation account

resource "azurerm_automation_account" "auto_acc" {
  name                = "${var.name}-autoacc"
  location            = var.location
  resource_group_name = var.rg_name
  sku_name            = "Free"
  tags                = var.tags
}
