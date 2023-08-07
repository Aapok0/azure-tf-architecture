output "webserver_public_ip_out" {
  value = azurerm_linux_virtual_machine.webserver_vm.public_ip_address
}

output "admin_pass_out" {
  sensitive = true
  value     = azurerm_linux_virtual_machine.webserver_vm.admin_password
}
