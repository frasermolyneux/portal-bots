# checkov:skip=CKV_AZURE_41: "Ensure that the expiration date is set on all secrets" - This is a manually managed secret by design.
resource "azurerm_key_vault_secret" "mysql_connection_string" {
  name         = "mysql-connection-string"
  value        = "placeholder"
  key_vault_id = azurerm_key_vault.kv.id

  lifecycle {
    ignore_changes = [value]
  }
}
