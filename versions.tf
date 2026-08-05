# Provider versions are pinned to a minor series: a patch release can still be
# picked up, but an upgrade that could change behaviour is an explicit change
# here. .terraform.lock.hcl pins the exact versions and is committed.

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
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}
