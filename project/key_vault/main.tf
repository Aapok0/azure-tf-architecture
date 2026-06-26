# Key Vault for project secrets (RBAC authorization model)

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

# Data-plane access for the deploying principal (also needed to write the secrets below)
resource "azurerm_role_assignment" "admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_object_id
}

resource "azurerm_key_vault_secret" "secrets" {
  # Secret names are not sensitive (e.g. "<vm>-admin-password"); values are.
  for_each     = nonsensitive(toset(keys(var.secrets)))
  name         = each.value
  value        = var.secrets[each.value]
  key_vault_id = azurerm_key_vault.kv.id
  tags         = var.tags

  # Role assignment must exist (and propagate) before data-plane writes succeed.
  depends_on = [azurerm_role_assignment.admin]
}
