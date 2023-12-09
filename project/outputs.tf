output "private_ip_out" {
  value = values(module.linux_vms)[*].private_ip_out
}

output "public_ip_out" {
  value = values(module.linux_vms)[*].public_ip_out
}

output "admin_pass_out" {
  sensitive = true
  value     = values(module.linux_vms)[*].admin_pass_out
}
