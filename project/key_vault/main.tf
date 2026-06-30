# Key Vault module: an RBAC-authorized vault holding the project's secrets (VM
# admin usernames/passwords/public keys). The deploying principal is granted Key
# Vault Administrator so it can write the secrets in the same apply.

resource "azurerm_key_vault" "kv" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.rg_name
  tenant_id                  = var.tenant_id
  sku_name                   = var.sku
  rbac_authorization_enabled = true
  purge_protection_enabled   = var.purge_protection
  soft_delete_retention_days = var.soft_delete_retention_days
  tags                       = var.tags
}

resource "azurerm_role_assignment" "admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_object_id
}

resource "azurerm_key_vault_secret" "secrets" {
  for_each     = nonsensitive(toset(keys(var.secrets)))
  name         = each.value
  value        = var.secrets[each.value]
  key_vault_id = azurerm_key_vault.kv.id
  tags         = var.tags

  depends_on = [azurerm_role_assignment.admin]
}
