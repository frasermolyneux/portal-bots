resource "azuread_application" "client_app" {
  display_name     = local.application_name
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "client_app" {
  client_id                    = azuread_application.client_app.client_id
  app_role_assignment_required = false

  owners = [
    data.azuread_client_config.current.object_id
  ]
}

resource "azuread_application_password" "client_app" {
  application_id = azuread_application.client_app.id

  rotate_when_changed = {
    rotation = time_rotating.thirty_days.id
  }
}

resource "azuread_app_role_assignment" "client_app" {
  app_role_id         = data.azuread_service_principal.repository_api.app_roles[index(data.azuread_service_principal.repository_api.app_roles.*.display_name, "ServiceAccount")].id
  principal_object_id = azuread_service_principal.client_app.object_id
  resource_object_id  = data.azuread_service_principal.repository_api.object_id
}
