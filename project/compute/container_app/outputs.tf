output "fqdn_out" {
  description = "Ingress FQDN of the Container App."
  value       = azurerm_container_app.app.ingress[0].fqdn
}

output "custom_domain_verification_id_out" {
  description = "Domain ownership verification ID used when binding custom domains."
  value       = azurerm_container_app.app.custom_domain_verification_id
}
