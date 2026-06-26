# Local variables

locals {
  tags = {
    location    = "${var.location}"
    environment = "${var.environment}"
    project     = "${var.project}"
  }

  name_prefix = "${var.location_abbreviation[var.location]}-${var.environment}-${var.project}"

  # VM credentials keyed by VM name, merged across all VM groups in the project.
  vm_secrets = merge([for k, m in module.linux_vms : m.secrets_out]...)

  # Flatten into individual Key Vault secrets. SSH private key is added out-of-band
  # (see README) so it never passes through Terraform state.
  kv_secrets = merge([
    for vmname, s in local.vm_secrets : {
      "${vmname}-admin-username" = s.admin_username
      "${vmname}-admin-password" = s.admin_password
      "${vmname}-ssh-public-key" = s.ssh_public_key
    }
  ]...)
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

# Key Vault for VM credentials

module "key_vault" {
  source = "./key_vault"

  count = var.key_vault_enabled ? 1 : 0

  name            = "${local.name_prefix}-kv"
  location        = var.location
  rg_name         = azurerm_resource_group.project_rg.name
  tenant_id       = var.tenant_id
  admin_object_id = var.admin_object_id

  secrets = local.kv_secrets

  tags = merge(var.tf_tags, local.tags)
}

# DNS zone

module "dns_zone" {
  source = "./dns_zone"

  for_each = var.domains

  # Dependencies and info
  name    = each.key
  rg_name = azurerm_resource_group.project_rg.name

  # Records
  records       = lookup(each.value, "records", {})
  ttl           = lookup(each.value, "ttl", 300)
  vm_public_ips = flatten(values(module.linux_vms)[*].public_ip_out)

  # Tags
  tags = merge(var.tf_tags, local.tags)
}
