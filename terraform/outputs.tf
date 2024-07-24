output "client_app_id" {
  value = azuread_application.client_app.object_id
}

output "client_app_secret" {
  value     = azuread_application_password.client_app.value
  sensitive = true
}

output "repository_subscription_key" {
  value     = azurerm_api_management_subscription.repository_api.primary_key
  sensitive = true
}

output "event_ingest_subscription_key" {
  value     = azurerm_api_management_subscription.event_ingest_api.primary_key
  sensitive = true
}
