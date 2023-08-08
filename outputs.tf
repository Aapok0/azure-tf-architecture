output "webserver_private_ip_out" {
  value = module.webserver_homepage_prd.webserver_private_ip_out
}

output "webserver_public_ip_out" {
  value = module.webserver_homepage_prd.webserver_public_ip_out
}

output "admin_pass_out" {
  sensitive = true
  value     = module.webserver_homepage_prd.admin_pass_out
}
