output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function."
  value       = module.lambda_function.function_arn
}

output "lambda_function_name" {
  description = "Name of the deployed Lambda function."
  value       = module.lambda_function.function_name
}

output "lambda_version" {
  description = "Published version of the function this run deployed."
  value       = module.lambda_function.version
}

output "artifact_version_id" {
  description = "S3 object version of the package that was deployed, for tracing a running function back to a build."
  value       = module.lambda_function.artifact_version_id
}

output "harness_service_id" {
  description = "Identifier of the Harness service representing this function."
  value       = module.harness_lambda_service.service_id
}
