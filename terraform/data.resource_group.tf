data "azurerm_resource_group" "core" {
  name = data.terraform_remote_state.portal_core.outputs.api_management.resource_group_name
}
