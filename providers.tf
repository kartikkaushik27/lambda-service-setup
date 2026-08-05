provider "aws" {
  region = var.aws_region

  # Short-lived STS credentials, supplied as TF_VAR_* environment variables.
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  token      = var.aws_session_token

  # Tagging every resource here means individual resources never have to
  # remember to do it.
  default_tags {
    tags = local.common_tags
  }
}

provider "harness" {
  account_id       = var.harness_account_id
  platform_api_key = var.harness_platform_api_key
}

provider "github" {
  owner = var.github_owner
  token = var.github_token
}
