resource "harness_platform_connector_aws" "this" {
  identifier = "aws_lambda_connector"
  name       = "AWS Lambda Connector"
  org_id     = var.harness_org_id
  project_id = harness_platform_project.this.identifier

  manual {
    access_key_ref    = harness_platform_secret_text.aws_access_key_id.identifier
    secret_key_ref    = harness_platform_secret_text.aws_secret_access_key.identifier
    session_token_ref = harness_platform_secret_text.aws_session_token.identifier
    region             = var.aws_region
  }
}

resource "harness_platform_connector_github" "this" {
  identifier          = "github_connector"
  name                = "GitHub Connector"
  org_id              = var.harness_org_id
  project_id          = harness_platform_project.this.identifier
  url                 = "https://github.com/${var.github_owner}/${var.github_repo_name}"
  connection_type     = "Repo"
  execute_on_delegate = false

  credentials {
    http {
      username  = var.github_owner
      token_ref = harness_platform_secret_text.github_pat.identifier
    }
  }

  depends_on = [github_repository.this]
}
