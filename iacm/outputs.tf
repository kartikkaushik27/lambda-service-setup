output "lambda_function_arns" {
  description = "ARN of every deployed Lambda function, keyed by lambda name."
  value       = { for key, mod in module.lambda : key => mod.function_arn }
}

output "lambda_versions" {
  description = "Published version of every function this run deployed, keyed by lambda name."
  value       = { for key, mod in module.lambda : key => mod.version }
}

output "artifact_version_ids" {
  description = "S3 object version of every deployed package, keyed by lambda name - for tracing a running function back to a build."
  value       = { for key, mod in module.lambda : key => mod.artifact_version_id }
}

output "harness_service_ids" {
  description = "Identifier of every Harness service created, keyed by lambda name."
  value       = { for key, mod in module.service : key => mod.service_id }
}

output "harness_environment_id" {
  description = "Environment created for this (project, environment, region), if this workspace manages its own."
  value       = var.manage_environment ? module.environment[0].environment_id : null
}

output "harness_infrastructure_id" {
  description = "Infrastructure definition created for this (project, environment, region), if this workspace manages its own."
  value       = var.manage_environment ? module.environment[0].infrastructure_id : null
}
