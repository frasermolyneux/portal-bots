data "azurerm_key_vault_secret" "portal_bots_client_secret" {
  name         = local.portal_bots.key_vault.secrets.client_secret.name
  key_vault_id = local.portal_bots.key_vault.id
}

data "azurerm_key_vault_secret" "mysql_connection_string" {
  name         = azurerm_key_vault_secret.mysql_connection_string.name
  key_vault_id = azurerm_key_vault.kv.id
}

output "client_app_id" {
  description = "Portal bots application client id."
  value       = local.portal_bots.application.client_id
}

output "client_app_secret" {
  description = "Portal bots application client secret for bot configuration."
  value       = data.azurerm_key_vault_secret.portal_bots_client_secret.value
  sensitive   = true
}

output "repository_api_audience" {
  description = "Audience for acquiring tokens for the repository API."
  value       = local.repository_api.application.primary_identifier_uri
}

output "event_ingest_api_audience" {
  description = "Audience for acquiring tokens for the event ingest API."
  value       = local.event_ingest_api.application.primary_identifier_uri
}

output "mysql_connection_string" {
  description = "MySQL connection string used by the bots."
  value       = data.azurerm_key_vault_secret.mysql_connection_string.value
  sensitive   = true
}

output "repository_api_base_url" {
  description = "Base URL for the repository API (APIM front door)."
  value       = local.repository_api.api_management.endpoint
}

output "event_ingest_api_base_url" {
  description = "Base URL for the event ingest API (APIM front door)."
  value       = local.event_ingest_api.api_management.endpoint
}

