output "subnets_id_out" {
  value = tomap({
    for key, id in azurerm_subnet.project_snet[*].id : key => id
  })
}

output "nsg_name_out" {
  description = "Name of the subnet's NSG, or null if no rules were defined."
  value       = length(var.nsg_rules) > 0 ? azurerm_network_security_group.nsg[0].name : null
}
