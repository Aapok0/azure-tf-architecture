# DNS zone module: a public DNS zone plus the A, CNAME and TXT records passed in
# by the caller. The records are agnostic to what they point at — e.g. A records
# to server IPs, or an apex A / CNAME / asuid TXT set for a Container App custom
# domain.

resource "azurerm_dns_zone" "zone" {
  name                = var.name
  resource_group_name = var.rg_name

  tags = var.tags
}

resource "azurerm_dns_a_record" "a" {
  for_each = var.a_records

  name                = each.key
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = var.rg_name
  ttl                 = var.ttl
  records             = each.value
}

resource "azurerm_dns_cname_record" "cname" {
  for_each = var.cname_records

  name                = each.key
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = var.rg_name
  ttl                 = var.ttl
  record              = each.value
}

resource "azurerm_dns_txt_record" "txt" {
  for_each = var.txt_records

  name                = each.key
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = var.rg_name
  ttl                 = var.ttl

  dynamic "record" {
    for_each = each.value
    content {
      value = record.value
    }
  }
}
