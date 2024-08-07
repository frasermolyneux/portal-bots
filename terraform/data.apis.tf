data "azurerm_api_management_api" "repository_api" {
  name                = var.repository_api.apim_api_name
  api_management_name = data.azurerm_api_management.core.name
  resource_group_name = data.azurerm_api_management.core.resource_group_name

  revision = var.repository_api.apim_api_revision
}

data "azurerm_api_management_api" "event_ingest_api" {
  name                = var.event_ingest_api.apim_api_name
  api_management_name = data.azurerm_api_management.core.name
  resource_group_name = data.azurerm_api_management.core.resource_group_name

  revision = var.event_ingest_api.apim_api_revision
}
