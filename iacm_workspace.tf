# Harness IACM (Infrastructure as Code Management) workspace. This is the
# one-time *configuration* of where/how to run Terraform - the pipeline's
# IACM stage (see harness_pipeline.tf) actually executes init/plan/apply
# against it on every run, which is what creates the AWS Lambda function and
# the Harness service (see iacm/main.tf, pushed to the GitHub repo this
# workspace points at).

resource "harness_platform_workspace" "lambda" {
  identifier           = "lambda_iacm_workspace"
  name                 = "Lambda IACM Workspace"
  org_id               = var.harness_org_id
  project_id           = harness_platform_project.this.identifier
  provisioner_type     = "opentofu"
  repository           = "https://github.com/${var.github_owner}/${var.github_repo_name}"
  repository_branch    = var.github_branch
  repository_path      = "iacm"
  repository_connector = harness_platform_connector_github.this.identifier

  # NOTE: the workspace `connector` block (type = "aws") only injects a
  # static AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY pair - it drops the
  # session token, so it can't be used with our STS-based connector. Instead
  # we inject all three as plain environment variables, which the "aws"
  # provider in iacm/providers.tf picks up directly.
  environment_variable {
    key        = "AWS_ACCESS_KEY_ID"
    value      = harness_platform_secret_text.aws_access_key_id.identifier
    value_type = "secret"
  }
  environment_variable {
    key        = "AWS_SECRET_ACCESS_KEY"
    value      = harness_platform_secret_text.aws_secret_access_key.identifier
    value_type = "secret"
  }
  environment_variable {
    key        = "AWS_SESSION_TOKEN"
    value      = harness_platform_secret_text.aws_session_token.identifier
    value_type = "secret"
  }

  terraform_variable {
    key        = "function_name"
    value      = var.function_name
    value_type = "string"
  }
  terraform_variable {
    key        = "runtime"
    value      = var.runtime
    value_type = "string"
  }
  terraform_variable {
    key        = "handler"
    value      = var.handler
    value_type = "string"
  }
  terraform_variable {
    key        = "memory_size"
    value      = tostring(var.memory_size)
    value_type = "string"
  }
  terraform_variable {
    key        = "timeout"
    value      = tostring(var.timeout)
    value_type = "string"
  }
  terraform_variable {
    key        = "lambda_role_arn"
    value      = aws_iam_role.lambda_exec.arn
    value_type = "string"
  }
  terraform_variable {
    key        = "aws_region"
    value      = var.aws_region
    value_type = "string"
  }
  terraform_variable {
    key        = "s3_bucket"
    value      = aws_s3_bucket.lambda_artifacts.id
    value_type = "string"
  }
  terraform_variable {
    key        = "s3_key"
    value      = local.lambda_artifact_key
    value_type = "string"
  }
  terraform_variable {
    key        = "harness_account_id"
    value      = var.harness_account_id
    value_type = "string"
  }
  terraform_variable {
    key        = "harness_org_id"
    value      = var.harness_org_id
    value_type = "string"
  }
  terraform_variable {
    key        = "harness_project_id"
    value      = harness_platform_project.this.identifier
    value_type = "string"
  }
  terraform_variable {
    key        = "github_connector_id"
    value      = harness_platform_connector_github.this.identifier
    value_type = "string"
  }
  terraform_variable {
    key        = "github_branch"
    value      = var.github_branch
    value_type = "string"
  }
  terraform_variable {
    key        = "aws_connector_id"
    value      = harness_platform_connector_aws.this.identifier
    value_type = "string"
  }
  terraform_variable {
    key        = "harness_platform_api_key"
    value      = harness_platform_secret_text.harness_pat.identifier
    value_type = "secret"
  }

  depends_on = [
    harness_platform_connector_github.this,
    harness_platform_connector_aws.this,
    harness_platform_secret_text.harness_pat,
    local_file.lambda_function_definition,
  ]
}
