# Subnet

resource "azurerm_subnet" "project_snet" {
  name                 = var.name
  resource_group_name  = var.rg_name
  virtual_network_name = var.vnet_name
  address_prefixes     = var.cidr
}

# Network security group, security rules and association

resource "azurerm_network_security_group" "nsg" {
  count               = length(var.nsg_rules) > 0 ? 1 : 0
  name                = "${var.name}-nsg"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "nsg_rule" {
  for_each                    = var.nsg_rules
  resource_group_name         = var.rg_name
  network_security_group_name = azurerm_network_security_group.nsg[0].name

  name                         = each.value["name"]
  priority                     = each.value["priority"]
  direction                    = each.value["direction"]
  access                       = each.value["access"]
  protocol                     = each.value["protocol"]
  source_address_prefixes      = lookup(each.value, "source_address_prefixes", null)
  source_address_prefix        = lookup(each.value, "source_address_prefix", null)
  source_port_ranges           = lookup(each.value, "source_port_ranges", null)
  source_port_range            = lookup(each.value, "source_port_range", null)
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefix", null)
  destination_port_ranges      = lookup(each.value, "destination_port_ranges", null)
  destination_port_range       = lookup(each.value, "destination_port_range", null)
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  count                     = length(var.nsg_rules) > 0 ? 1 : 0
  subnet_id                 = azurerm_subnet.project_snet.id
  network_security_group_id = azurerm_network_security_group.nsg[0].id
}
