locals {
  # Remote State References
  workload_resource_groups = {
    for location in [var.location] :
    location => data.terraform_remote_state.platform_workloads.outputs.workload_resource_groups[var.workload_name][var.environment].resource_groups[lower(location)]
  }

  workload_backend = try(
    data.terraform_remote_state.platform_workloads.outputs.workload_terraform_backends[var.workload_name][var.environment],
    null
  )

  workload_administrative_unit = try(
    data.terraform_remote_state.platform_workloads.outputs.workload_administrative_units[var.workload_name][var.environment],
    null
  )

  workload_resource_group = local.workload_resource_groups[var.location]

  action_group_map = {
    critical      = data.terraform_remote_state.platform_monitoring.outputs.monitor_action_groups.critical
    high          = data.terraform_remote_state.platform_monitoring.outputs.monitor_action_groups.high
    moderate      = data.terraform_remote_state.platform_monitoring.outputs.monitor_action_groups.moderate
    low           = data.terraform_remote_state.platform_monitoring.outputs.monitor_action_groups.low
    informational = data.terraform_remote_state.platform_monitoring.outputs.monitor_action_groups.informational
  }

  api_management   = data.terraform_remote_state.portal_environments.outputs.api_management
  event_ingest_api = data.terraform_remote_state.portal_environments.outputs.event_ingest_api
  repository_api   = data.terraform_remote_state.portal_environments.outputs.repository_api
  portal_bots      = data.terraform_remote_state.portal_environments.outputs.portal_bots
  portal_core      = data.terraform_remote_state.portal_core.outputs

  portal_bots_key_vault_name = substr(format("kv-bot-%s-%s", random_id.portal_bots.hex, var.location), 0, 24)
}
