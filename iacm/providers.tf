provider "aws" {
  region = var.aws_region

  # Credentials come from AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY /
  # AWS_SESSION_TOKEN, injected by the workspace's credentials variable set.
  default_tags {
    tags = var.tags
  }
}

# Reads HARNESS_ACCOUNT_ID and HARNESS_PLATFORM_API_KEY from the environment,
# also from the credentials variable set.
provider "harness" {}
