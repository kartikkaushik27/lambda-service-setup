output "lambda_execution_role_arn" {
  description = "ARN of the execution role the deployed function assumes."
  value       = aws_iam_role.lambda_exec.arn
}

output "artifact_bucket" {
  description = "Bucket the CI stage publishes deployment packages to."
  value       = aws_s3_bucket.artifacts.id
}

output "artifact_key" {
  description = "Stable object key the IACM stage deploys the function from."
  value       = local.artifact_key
}

output "harness_environment_id" {
  description = "Environment the native deploy stage targets."
  value       = module.environment.environment_id
}

output "harness_infrastructure_id" {
  description = "Infrastructure definition the native deploy stage targets."
  value       = module.environment.infrastructure_id
}

output "harness_workspace_id" {
  description = "IACM workspace the pipeline's provisioning stage runs."
  value       = harness_platform_workspace.this.identifier
}

output "harness_pipeline_id" {
  description = "Identifier of the build/provision/deploy/verify pipeline."
  value       = harness_platform_pipeline.this.identifier
}

output "harness_service_id" {
  description = "Identifier of the Harness service the IACM stage creates."
  value       = local.service_identifier
}

output "github_repository_url" {
  description = "Repository the pipeline and IACM workspace read from."
  value       = github_repository.this.html_url
}

output "pipeline_yaml" {
  description = "Rendered pipeline YAML, for reviewing what was applied without opening the Harness UI."
  value       = harness_platform_pipeline.this.yaml
}
