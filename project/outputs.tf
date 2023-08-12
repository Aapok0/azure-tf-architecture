output "name_prefix" {
  value = local.name_prefix
}

output "location" {
  value = azurerm_resource_group.project_rg.location
}

output "name" {
  value = azurerm_resource_group.project_rg.name
}

output "subnets" {
  value = azurerm_subnet.project_snet
}

output "tags" {
  value = local.tags
}
