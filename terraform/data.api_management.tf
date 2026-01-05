data "azurerm_api_management" "core" {
  name                = data.terraform_remote_state.portal_core.outputs.api_management.name
  resource_group_name = data.azurerm_resource_group.core.name
}
