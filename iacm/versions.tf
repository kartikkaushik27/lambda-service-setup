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
    # Only needed to read the state of module.lambda's placeholder resource
    # while the "removed" block below drops it - remove this once every
    # workspace has applied at least once after that change.
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4"
    }
  }
}
