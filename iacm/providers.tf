provider "aws" {
  region = var.aws_region
  # No static credentials here - the Harness IACM workspace's "aws" connector
  # (see connector block in iacm_workspace.tf) injects short-lived AWS
  # credentials into this run automatically.
}

provider "harness" {
  endpoint         = "https://app.harness.io/gateway"
  account_id       = var.harness_account_id
  platform_api_key = var.harness_platform_api_key
}
