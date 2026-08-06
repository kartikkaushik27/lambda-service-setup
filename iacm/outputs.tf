output "lambda_function_arns" {
  description = "ARN of every deployed Lambda function, keyed by lambda name."
  value       = { for key, mod in module.lambda : key => mod.function_arn }
}

output "lambda_versions" {
  description = "Published version of every function this run deployed, keyed by lambda name."
  value       = { for key, mod in module.lambda : key => mod.version }
}

output "harness_service_ids" {
  description = "Identifier of every Harness service created, keyed by lambda name."
  value       = { for key, mod in module.service : key => mod.service_id }
}

output "harness_environment_id" {
  description = "Environment shared by every region this (project, environment_name) deploys to. Always the same identifier whether or not this workspace created it."
  value       = "${local.project_key}_${var.environment_name}"
}

output "harness_infrastructure_id" {
  description = "Infrastructure definition created for this (project, environment_name, region), if this workspace manages its own."
  value       = var.manage_infrastructure ? harness_platform_infrastructure.this[0].identifier : null
}
