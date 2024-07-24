data "azuread_service_principal" "repository_api" {
  display_name = var.repository_api.application_name
}

data "azuread_service_principal" "event_ingest_api" {
  display_name = var.event_ingest_api.application_name
}
