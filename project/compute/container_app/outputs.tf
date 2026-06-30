output "fqdn_out" {
  description = "Ingress FQDN of the Container App."
  value       = azurerm_container_app.app.ingress[0].fqdn
}

output "custom_domain_verification_id_out" {
  description = "Domain ownership verification ID used when binding custom domains (asuid TXT record value)."
  value       = azurerm_container_app.app.custom_domain_verification_id
}

output "app_id_out" {
  description = "Resource ID of the Container App."
  value       = azurerm_container_app.app.id
}

output "environment_id_out" {
  description = "Resource ID of the Container App Environment."
  value       = azurerm_container_app_environment.env.id
}

output "environment_static_ip_out" {
  description = "Static inbound IP of the environment. Apex (A record) custom domains point here."
  value       = azurerm_container_app_environment.env.static_ip_address
}
