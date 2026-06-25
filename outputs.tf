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
