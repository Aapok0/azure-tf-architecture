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
