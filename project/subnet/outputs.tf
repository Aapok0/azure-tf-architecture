output "subnets_id_out" {
  value = tomap({
    for key, id in azurerm_subnet.project_snet[*].id : key => id
  })
}
