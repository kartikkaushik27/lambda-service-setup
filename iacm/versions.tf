# Standalone configuration with its own state, managed by the Harness IACM
# workspace rather than by the root configuration.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
    harness = {
      source  = "harness/harness"
      version = "~> 0.44"
    }
  }
}
