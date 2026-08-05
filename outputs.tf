output "github_repository_url" {
  description = "Repository holding this configuration and the function source."
  value       = github_repository.this.html_url
}

output "lambda_execution_role_arn" {
  description = "ARN of the IAM role the Lambda function runs as."
  value       = module.lambda_foundation.execution_role_arn
}

output "artifact_bucket" {
  description = "S3 bucket the CI stage publishes deployment packages to."
  value       = module.lambda_foundation.artifact_bucket
}

output "artifact_key" {
  description = "S3 key the CI stage publishes to and the IACM stage deploys from."
  value       = local.artifact_key
}

output "log_group_name" {
  description = "CloudWatch Logs group the function writes to."
  value       = module.lambda_foundation.log_group_name
}

output "harness_project_id" {
  description = "Identifier of the Harness project."
  value       = module.harness_project.project_id
}

output "harness_environment_id" {
  description = "Harness environment the native deploy stage targets."
  value       = module.harness_lambda_environment.environment_id
}

output "harness_infrastructure_id" {
  description = "Infrastructure definition the native deploy stage targets."
  value       = module.harness_lambda_environment.infrastructure_id
}

output "iacm_workspace_id" {
  description = "IACM workspace the deployment stage runs."
  value       = module.harness_iacm_workspace.workspace_id
}

output "iacm_credentials_variable_set_id" {
  description = "Credentials variable set, attachable to any further IACM workspace in this project."
  value       = module.harness_iacm_workspace.credentials_variable_set_id
}

output "harness_pipeline_url" {
  description = "Link to the pipeline in Harness."
  value       = "https://app.harness.io/ng/account/${var.harness_account_id}/module/cd/orgs/${var.harness_org_id}/projects/${module.harness_project.project_id}/pipelines/${module.harness_lambda_pipeline.pipeline_id}/pipeline-studio"
}
