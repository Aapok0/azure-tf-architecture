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
