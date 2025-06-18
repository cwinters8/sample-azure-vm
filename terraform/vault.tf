resource "azurerm_key_vault" "main" {
  name                      = "orions-vault"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  sku_name                  = "standard"
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization = true
}

resource "azuread_group" "keyvault_users" {
  display_name            = "KeyVault-Users"
  description             = "Users with access to the main Key Vault"
  security_enabled        = true
  prevent_duplicate_names = true
}

resource "azurerm_role_assignment" "keyvault_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azuread_group.keyvault_users.object_id
}

resource "azuread_group_member" "my_user" {
  group_object_id  = azuread_group.keyvault_users.object_id
  member_object_id = data.azurerm_client_config.current.object_id
}
