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
  records             = lookup(each.value, "ips", var.vm_public_ips)
}
