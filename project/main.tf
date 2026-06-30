# Project module: one resource group holding the project's virtual network and
# subnets/NSGs, its compute (Linux VMs and Container Apps), DNS zones, and a Key
# Vault for the generated VM credentials. Resources are named with the
# <region-abbr>-<environment>-<project> prefix built below.

locals {
  tags = {
    location    = var.location
    environment = var.environment
    project     = var.project
  }

  name_prefix = "${var.location_abbreviation[var.location]}-${var.environment}-${var.project}"

  vm_secrets = merge([for k, m in module.linux_vms : m.secrets_out]...)

  # SSH private key is added out-of-band (see README) so it never passes through state.
  kv_secrets = merge([
    for vmname, s in local.vm_secrets : {
      "${vmname}-admin-username" = s.admin_username
      "${vmname}-admin-password" = s.admin_password
      "${vmname}-ssh-public-key" = s.ssh_public_key
    }
  ]...)

  vm_public_ips = flatten(values(module.linux_vms)[*].public_ip_out)

  domain_dns = {
    for dk, d in var.domains : dk => d.container_app != null ? {
      a_records = {
        for h in d.hostnames : h => [module.container_apps[d.container_app].environment_static_ip_out]
        if h == "@"
      }
      cname_records = {
        for h in d.hostnames : h => module.container_apps[d.container_app].fqdn_out
        if h != "@"
      }
      txt_records = {
        for h in d.hostnames : (h == "@" ? "asuid" : "asuid.${h}") => [module.container_apps[d.container_app].custom_domain_verification_id_out]
      }
      } : {
      a_records     = { for rk, r in d.records : rk => (r.ips != null ? r.ips : local.vm_public_ips) }
      cname_records = {}
      txt_records   = {}
    }
  }

  # Apex can't be a CNAME, so it validates over HTTP; subdomains validate via CNAME.
  container_app_domains = merge(concat([{}], [
    for dk, d in var.domains : {
      for h in d.hostnames : "${dk}/${h}" => {
        container_app     = d.container_app
        hostname          = h == "@" ? dk : "${h}.${dk}"
        validation_method = h == "@" ? "HTTP" : "CNAME"
      }
    } if d.container_app != null
  ])...)
}

resource "azurerm_resource_group" "project_rg" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = merge(var.tf_tags, local.tags)
}

# Skipped when var.subnets is empty (e.g. compute on a managed network).
resource "azurerm_virtual_network" "project_vnet" {
  count               = length(var.subnets) > 0 ? 1 : 0
  name                = "${local.name_prefix}-vnet"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name
  address_space       = var.vnet
  tags                = merge(var.tf_tags, local.tags)
}

module "subnet" {
  source = "./subnet"

  for_each = var.subnets

  name              = "${local.name_prefix}-${each.key}-snet"
  location          = var.location
  rg_name           = azurerm_resource_group.project_rg.name
  vnet_name         = azurerm_virtual_network.project_vnet[0].name
  cidr              = each.value.cidr
  nsg_rules         = each.value.nsg_rules
  admin_allowed_ips = var.admin_allowed_ips
  tags              = merge(var.tf_tags, local.tags)
}

module "linux_vms" {
  source = "./compute/linux_vms"

  for_each = var.vms

  name                       = "${local.name_prefix}-${each.key}-vm"
  location                   = azurerm_resource_group.project_rg.location
  rg_name                    = azurerm_resource_group.project_rg.name
  subnet_id                  = lookup(module.subnet[each.value.subnet].subnets_id_out, "0", "")
  log_analytics_workspace_id = each.value.log_analytics ? var.log_analytics_workspace_id : null
  details                    = each.value
  tags                       = merge(var.tf_tags, local.tags, each.value.service_tags)
}

module "container_apps" {
  source = "./compute/container_app"

  for_each = var.container_apps

  name                       = "${local.name_prefix}-${each.key}-ca"
  location                   = azurerm_resource_group.project_rg.location
  rg_name                    = azurerm_resource_group.project_rg.name
  log_analytics_workspace_id = each.value.log_analytics ? var.log_analytics_workspace_id : null
  details                    = each.value
  tags                       = merge(var.tf_tags, local.tags, each.value.service_tags)
}

module "key_vault" {
  source = "./key_vault"

  count = var.key_vault_enabled ? 1 : 0

  name            = "${local.name_prefix}-kv"
  location        = var.location
  rg_name         = azurerm_resource_group.project_rg.name
  tenant_id       = var.tenant_id
  admin_object_id = var.admin_object_id
  secrets         = local.kv_secrets
  tags            = merge(var.tf_tags, local.tags)
}

module "dns_zone" {
  source = "./dns_zone"

  for_each = var.domains

  name          = each.key
  rg_name       = azurerm_resource_group.project_rg.name
  ttl           = each.value.ttl
  a_records     = local.domain_dns[each.key].a_records
  cname_records = local.domain_dns[each.key].cname_records
  txt_records   = local.domain_dns[each.key].txt_records
  tags          = merge(var.tf_tags, local.tags)
}

# Managed cert id/binding type are in ignore_changes because Azure sets them
# asynchronously. The cert is not attached here (cycle with the custom domain);
# run az containerapp hostname bind once per hostname after apply — see README.
resource "azurerm_container_app_custom_domain" "ca" {
  for_each = local.container_app_domains

  name             = each.value.hostname
  container_app_id = module.container_apps[each.value.container_app].app_id_out

  lifecycle {
    ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
  }

  depends_on = [module.dns_zone]
}

resource "azurerm_container_app_environment_managed_certificate" "ca" {
  for_each = local.container_app_domains

  name                         = replace(each.value.hostname, ".", "-")
  container_app_environment_id = module.container_apps[each.value.container_app].environment_id_out
  subject_name                 = each.value.hostname
  domain_control_validation    = each.value.validation_method
  tags                         = merge(var.tf_tags, local.tags)

  depends_on = [azurerm_container_app_custom_domain.ca]
}
