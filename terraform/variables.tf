variable "environment" {
  default = "dev"
}

variable "location" {
  default = "uksouth"
}

variable "instance" {
  default = "01"
}

variable "subscription_id" {}

variable "api_management_name" {}

variable "portal_environments_state" {
  description = "Backend config for portal-environments remote state"
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    key                  = string
    subscription_id      = string
    tenant_id            = string
  })
}

variable "repository_api" {
  type = object({
    application_name     = string
    application_audience = string
    apim_product_id      = string
  })
  default = {
    application_name     = "portal-repository-dev-01"
    application_audience = "api://e56a6947-bb9a-4a6e-846a-1f118d1c3a14/portal-repository-dev-01"
    apim_product_id      = ""
  }
}

variable "event_ingest_api_product_id" {
  description = "API Management product identifier for the event ingest API"
  type        = string
  default     = ""
}

variable "tags" {
  default = {}
}
