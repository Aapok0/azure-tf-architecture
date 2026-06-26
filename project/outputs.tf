output "private_ip_info_out" {
  value = flatten(values(module.linux_vms)[*].private_ip_info_out)
}

output "public_ip_info_out" {
  value = flatten(values(module.linux_vms)[*].public_ip_info_out)
}

output "public_ip_out" {
  value = flatten(values(module.linux_vms)[*].public_ip_out)
}

output "admin_pass_out" {
  sensitive = true
  value     = values(module.linux_vms)[*].admin_pass_out
}

output "admin_user_out" {
  value = flatten(values(module.linux_vms)[*].admin_user_out)
}

output "ansible_hosts_out" {
  description = "VM connection details for homepage-webserver-ansible inventory sync."
  value       = flatten(values(module.linux_vms)[*].ansible_hosts_out)
}

output "key_vault_name_out" {
  description = "Key Vault name for the project (null if disabled)."
  value       = var.key_vault_enabled ? module.key_vault[0].vault_name_out : null
}

output "key_vault_uri_out" {
  description = "Key Vault URI for the project (null if disabled)."
  value       = var.key_vault_enabled ? module.key_vault[0].vault_uri_out : null
}
