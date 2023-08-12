output "private_ip_out" {
  value = module.webserver_vm.private_ip_out
}

output "public_ip_out" {
  value = module.webserver_vm.public_ip_out
}

output "admin_pass_out" {
  sensitive = true
  value     = module.webserver_vm.admin_pass_out
}
