output "client_app_id" {
  value = azuread_application.client_app.client_id
}

output "client_app_secret" {
  value     = azuread_application_password.client_app.value
  sensitive = true
}

output "repository_subscription_key" {
  value     = azurerm_api_management_subscription.repository_api_subscription.primary_key
  sensitive = true
}

output "event_ingest_subscription_key" {
  value     = azurerm_api_management_subscription.event_ingest_api.primary_key
  sensitive = true
}

output "mysql_connection_string" {
  value     = azurerm_key_vault_secret.mysql_connection_string.value
  sensitive = true
}
