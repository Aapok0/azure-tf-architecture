# Subnet module: one subnet plus an optional NSG. The NSG and its rules are only
# created when var.nsg_rules is non-empty, and the subnet is associated with it.

# Rules flagged admin_restricted get their source set from the central
# admin_allowed_ips list, so the SSH/ICMP allowlist lives in one place.
locals {
  effective_nsg_rules = {
    for k, r in var.nsg_rules : k => merge(r, {
      source_address_prefixes = r.admin_restricted ? var.admin_allowed_ips : r.source_address_prefixes
    })
  }
}

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
  for_each                    = local.effective_nsg_rules
  resource_group_name         = var.rg_name
  network_security_group_name = azurerm_network_security_group.nsg[0].name

  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_address_prefixes      = each.value.source_address_prefixes
  source_address_prefix        = each.value.source_address_prefix
  source_port_ranges           = each.value.source_port_ranges
  source_port_range            = each.value.source_port_range
  destination_address_prefixes = each.value.destination_address_prefixes
  destination_address_prefix   = each.value.destination_address_prefix
  destination_port_ranges      = each.value.destination_port_ranges
  destination_port_range       = each.value.destination_port_range
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  count                     = length(var.nsg_rules) > 0 ? 1 : 0
  subnet_id                 = azurerm_subnet.project_snet.id
  network_security_group_id = azurerm_network_security_group.nsg[0].id
}
