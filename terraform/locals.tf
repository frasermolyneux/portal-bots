locals {
  application_name    = "portal-bots-${var.environment}-${var.instance}"
  resource_group_name = "rg-portal-bots-${var.environment}-${var.location}-${var.instance}"
}
