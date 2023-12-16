output "private_ip_out" {
  value = values(module.project)[*].private_ip_out
}

output "public_ip_out" {
  value = values(module.project)[*].public_ip_out
}

output "admin_pass_out" {
  sensitive = true
  value     = values(module.project)[*].admin_pass_out
}
