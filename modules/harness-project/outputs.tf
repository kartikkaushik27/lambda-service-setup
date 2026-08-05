output "project_id" {
  description = "Identifier of the Harness project."
  value       = harness_platform_project.this.identifier
}

output "aws_connector_id" {
  description = "Identifier of the AWS connector."
  value       = harness_platform_connector_aws.this.identifier
}

output "github_connector_id" {
  description = "Identifier of the GitHub connector."
  value       = harness_platform_connector_github.this.identifier
}

output "secret_ids" {
  description = "Identifiers of the secrets created in the project, keyed by purpose."
  value = {
    aws_access_key_id     = harness_platform_secret_text.aws_access_key_id.identifier
    aws_secret_access_key = harness_platform_secret_text.aws_secret_access_key.identifier
    aws_session_token     = harness_platform_secret_text.aws_session_token.identifier
    github_pat            = harness_platform_secret_text.github_pat.identifier
    harness_pat           = harness_platform_secret_text.harness_pat.identifier
  }
}
