resource "azurerm_api_management_subscription" "repository_api" {
  api_management_name = data.azurerm_api_management.core.name
  resource_group_name = data.azurerm_api_management.core.resource_group_name

  state         = "active"
  allow_tracing = false

  api_id       = split(";", data.azurerm_api_management_api.repository_api.id)[0] // Strip revision from id when creating subscription
  display_name = format("%s-%s", local.application_name, data.azurerm_api_management_api.repository_api.name)
}

resource "azurerm_api_management_subscription" "event_ingest_api" {
  api_management_name = data.azurerm_api_management.core.name
  resource_group_name = data.azurerm_api_management.core.resource_group_name

  state         = "active"
  allow_tracing = false

  api_id       = split(";", data.azurerm_api_management_api.event_ingest_api.id)[0] // Strip revision from id when creating subscription
  display_name = format("%s-%s", local.application_name, data.azurerm_api_management_api.event_ingest_api)
}
