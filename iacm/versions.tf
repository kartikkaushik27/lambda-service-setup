# Terraform config executed by the Harness IACM workspace (see
# iacm_workspace.tf in the repo root). This is a standalone configuration -
# it is NOT part of the root module's state, it runs inside the pipeline's
# IACM stage every time the pipeline is executed.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    harness = {
      source  = "harness/harness"
      version = "~> 0.38"
    }
  }
}
