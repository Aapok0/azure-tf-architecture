output "nic_id_out" {
  value = azurerm_linux_virtual_machine.vm.network_interface_ids[0]
}

output "private_ip_info_out" {
  value = "${azurerm_linux_virtual_machine.vm.name}: ${azurerm_linux_virtual_machine.vm.private_ip_address}"
}

output "public_ip_info_out" {
  value = "${azurerm_linux_virtual_machine.vm.name}: ${azurerm_linux_virtual_machine.vm.public_ip_address}"
}

output "public_ip_out" {
  value = azurerm_linux_virtual_machine.vm.public_ip_address
}

output "admin_pass_out" {
  sensitive = true
  value     = "${azurerm_linux_virtual_machine.vm.name}: user=${azurerm_linux_virtual_machine.vm.admin_username} password=${random_password.admin_pass.result}"
}

output "admin_user_out" {
  value = "${azurerm_linux_virtual_machine.vm.name}: ${azurerm_linux_virtual_machine.vm.admin_username}"
}

output "secrets_out" {
  description = "Raw credentials for storing in Key Vault. Sensitive (includes the generated admin password)."
  sensitive   = true
  value = {
    admin_username = azurerm_linux_virtual_machine.vm.admin_username
    admin_password = random_password.admin_pass.result
    ssh_public_key = trimspace(file(pathexpand(var.admin_ssh_public_key_path)))
  }
}

output "ansible_host_out" {
  description = "Connection details for homepage-webserver-ansible inventory sync."
  value = var.public_ip && azurerm_linux_virtual_machine.vm.public_ip_address != null ? {
    vm_name           = azurerm_linux_virtual_machine.vm.name
    public_ip         = azurerm_linux_virtual_machine.vm.public_ip_address
    admin_user        = azurerm_linux_virtual_machine.vm.admin_username
    environment       = lookup(var.tags, "environment", "prd")
    service           = lookup(var.tags, "service", "")
    ssh_host_alias    = "${lookup(var.tags, "project", "vm")}-${lookup(var.tags, "service", "host")}-${lookup(var.tags, "node", "0")}"
    ssh_identity_file = replace(pathexpand(var.admin_ssh_public_key_path), ".pub", "")
  } : null
}
