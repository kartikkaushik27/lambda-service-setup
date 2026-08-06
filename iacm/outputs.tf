output "harness_service_ids" {
  description = "Identifier of every Harness service created, keyed by lambda name."
  value       = { for key, mod in module.service : key => mod.service_id }
}

output "harness_environment_id" {
  description = "Environment shared by every region this (project, environment_name) deploys to. Always the same identifier whether or not this workspace created it."
  value       = "${local.project_key}_${var.environment_name}"
}

output "harness_infrastructure_ids" {
  description = "Infrastructure definition identifier per lambda, keyed by lambda name."
  value       = { for key, infra in harness_platform_infrastructure.this : key => infra.identifier }
}
