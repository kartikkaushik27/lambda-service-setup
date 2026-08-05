output "workspace_id" {
  description = "Identifier of the IACM workspace."
  value       = harness_platform_workspace.this.identifier
}

output "credentials_variable_set_id" {
  description = "Identifier of the credentials variable set, reusable by other workspaces."
  value       = harness_platform_infra_variable_set.credentials.identifier
}
