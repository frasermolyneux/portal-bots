data "terraform_remote_state" "portal_environments" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.portal_environments_state.resource_group_name
    storage_account_name = var.portal_environments_state.storage_account_name
    container_name       = var.portal_environments_state.container_name
    key                  = var.portal_environments_state.key
    use_oidc             = true
    subscription_id      = var.portal_environments_state.subscription_id
    tenant_id            = var.portal_environments_state.tenant_id
  }
}
