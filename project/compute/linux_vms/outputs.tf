output "private_ip_info_out" {
  value = flatten(module.linux_vm[*].private_ip_info_out)
}

output "public_ip_info_out" {
  value = flatten(module.linux_vm[*].public_ip_info_out)
}

output "public_ip_out" {
  value = flatten(module.linux_vm[*].public_ip_out)
}

output "admin_pass_out" {
  sensitive = true
  value     = module.linux_vm[*].admin_pass_out
}

output "admin_user_out" {
  value = module.linux_vm[*].admin_user_out
}

output "ansible_hosts_out" {
  description = "VM connection details for homepage-webserver-ansible inventory sync."
  value       = [for host in module.linux_vm[*].ansible_host_out : host if host != null]
}
