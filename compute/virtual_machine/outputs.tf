output "nic_id_out" {
  value = azurerm_linux_virtual_machine.vm.network_interface_ids[0]
}

output "private_ip_out" {
  value = "${azurerm_linux_virtual_machine.vm.name}: ${azurerm_linux_virtual_machine.vm.private_ip_address}"
}

output "public_ip_out" {
  value = "${azurerm_linux_virtual_machine.vm.name}: ${azurerm_linux_virtual_machine.vm.public_ip_address}"
}

output "admin_pass_out" {
  sensitive = true
  value     = "${azurerm_linux_virtual_machine.vm.name}: ${azurerm_linux_virtual_machine.vm.admin_password}"
}
