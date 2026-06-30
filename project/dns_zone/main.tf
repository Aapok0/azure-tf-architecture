# DNS zone module: a public DNS zone for the domain with one A record per entry
# in var.records. A record targets its own ips, or the project VM public IPs when
# none are given.

resource "azurerm_dns_zone" "zone" {
  name                = var.name
  resource_group_name = var.rg_name

  tags = var.tags
}

resource "azurerm_dns_a_record" "a" {
  for_each = var.records

  name                = each.key
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = var.rg_name
  ttl                 = var.ttl
  records             = each.value.ips != null ? each.value.ips : var.vm_public_ips
}
