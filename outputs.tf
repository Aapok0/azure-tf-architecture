output "private_ip_info_out" {
  value = flatten(values(module.project)[*].private_ip_info_out)
}

output "public_ip_info_out" {
  value = flatten(values(module.project)[*].public_ip_info_out)
}

output "admin_pass_out" {
  sensitive = true
  value     = values(module.project)[*].admin_pass_out
}

output "admin_user_out" {
  description = "Generated VM admin usernames. Also included in ansible_hosts_out after sync."
  value       = flatten(values(module.project)[*].admin_user_out)
}

output "ansible_hosts_out" {
  description = "VM connection details for homepage-webserver-ansible. Run scripts/sync-ansible-inventory.sh after apply."
  value       = flatten(values(module.project)[*].ansible_hosts_out)
}

output "key_vault_name_out" {
  description = "Key Vault name per project for VM credentials. Use with: az keyvault secret show --vault-name <name> --name <secret>."
  value       = { for k, m in module.project : k => m.key_vault_name_out }
}

output "key_vault_uri_out" {
  description = "Key Vault URI per project."
  value       = { for k, m in module.project : k => m.key_vault_uri_out }
}
