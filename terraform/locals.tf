locals {
  application_name    = "portal-bots-${var.environment}-${var.instance}"
  resource_group_name = "rg-portal-bots-${var.environment}-${var.location}-${var.instance}"
  key_vault_name      = "kv-${random_id.environment_id.hex}-${var.location}"
}
