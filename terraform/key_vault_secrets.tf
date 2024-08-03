resource "azurerm_key_vault_secret" "mysql_connection_string" {
  name         = "mysql-connection-string"
  value        = "placeholder"
  key_vault_id = azurerm_key_vault.kv.id

  lifecycle {
    ignore_changes = [value]
  }
}
