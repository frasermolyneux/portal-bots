output "client_app_id" {
  value = azuread_application.client_app.object_id
}

output "client_app_secret" {
  value     = azuread_application_password.client_app.value
  sensitive = true
}
