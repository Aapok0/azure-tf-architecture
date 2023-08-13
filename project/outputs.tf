output "name_prefix_out" {
  value = local.name_prefix
}

output "rg_location_out" {
  value = azurerm_resource_group.project_rg.location
}

output "rg_name_out" {
  value = azurerm_resource_group.project_rg.name
}

output "subnets_out" {
  value = azurerm_subnet.project_snet
}

output "tags_out" {
  value = local.tags
}
