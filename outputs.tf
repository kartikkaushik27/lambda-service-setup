output "github_repository_url" {
  description = "URL of the GitHub repository created for this project."
  value       = github_repository.this.html_url
}

output "lambda_iam_role_arn" {
  description = "ARN of the IAM execution role created for the Lambda function."
  value       = aws_iam_role.lambda_exec.arn
}

output "lambda_artifact_bucket" {
  description = "S3 bucket holding the Lambda deployment package."
  value       = aws_s3_bucket.lambda_artifacts.id
}

output "lambda_artifact_key" {
  description = "S3 key the CI stage uploads the Lambda deployment package to (and the IACM stage reads it from)."
  value       = local.lambda_artifact_key
}

output "harness_pipeline_url" {
  description = "Direct link to the Harness pipeline studio for the created pipeline."
  value       = "https://app.harness.io/ng/account/${var.harness_account_id}/module/cd/orgs/${var.harness_org_id}/projects/${harness_platform_project.this.identifier}/pipelines/${harness_platform_pipeline.this.identifier}/pipeline-studio"
}
