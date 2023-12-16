# Local variables

locals {
  tags = {
    location    = "${var.location}"
    environment = "${var.environment}"
    project     = "${var.project}"
  }

  name_prefix = "${var.location_abbreviation[var.location]}-${var.environment}-${var.project}"
}

# Base resources

## Resource groups

resource "azurerm_resource_group" "project_rg" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = merge(var.tf_tags, local.tags)
}

## Virtual network and its subnets and security groups

resource "azurerm_virtual_network" "project_vnet" {
  name                = "${local.name_prefix}-vnet"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name
  address_space       = var.vnet
  tags                = merge(var.tf_tags, local.tags)
}

module "subnet" {
  source = "./subnet"

  for_each = var.subnets

  # Dependencies and info
  name      = "${local.name_prefix}-${each.key}-snet"
  location  = var.location
  rg_name   = azurerm_resource_group.project_rg.name
  vnet_name = azurerm_virtual_network.project_vnet.name

  # IP ranges
  cidr = lookup(each.value, "cidr", null)

  # Security group rules (won't create anything, if there's no rules)
  nsg_rules = lookup(each.value, "nsg_rules", {})

  # Tags
  tags = merge(var.tf_tags, local.tags)
}

# Compute resources

## Linux VMs

module "linux_vms" {
  source = "./compute/linux_vms"

  for_each = var.vms

  # Dependencies and info
  name      = "${local.name_prefix}-${each.key}-vm"
  location  = azurerm_resource_group.project_rg.location
  rg_name   = azurerm_resource_group.project_rg.name
  subnet_id = lookup(module.subnet[lookup(each.value, "subnet", "default")].subnets_id_out, "0", "")

  # Virtual machine details
  details = each.value

  # Tags
  tags = merge(var.tf_tags, local.tags, lookup(each.value, "service_tags"), {})
}
