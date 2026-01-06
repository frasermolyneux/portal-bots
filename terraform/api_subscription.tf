resource "azurerm_api_management_subscription" "repository_api_subscription" {
  api_management_name = local.core_api_management.name
  resource_group_name = local.core_api_management.resource_group_name

  state         = "active"
  allow_tracing = false

  product_id   = data.azurerm_api_management_product.repository_api_product.id
  display_name = format("%s-%s", local.application_name, data.azurerm_api_management_product.repository_api_product.product_id)
}

resource "azurerm_api_management_subscription" "event_ingest_api" {
  api_management_name = local.core_api_management.name
  resource_group_name = local.core_api_management.resource_group_name

  state         = "active"
  allow_tracing = false

  product_id   = data.terraform_remote_state.portal_core.outputs.event_ingest_api.product_resource_id
  display_name = format("%s-%s", local.application_name, data.terraform_remote_state.portal_core.outputs.event_ingest_api.product_id)
}
