output "vault_id_out" {
  value = azurerm_key_vault.kv.id
}

output "vault_name_out" {
  value = azurerm_key_vault.kv.name
}

output "vault_uri_out" {
  value = azurerm_key_vault.kv.vault_uri
}
