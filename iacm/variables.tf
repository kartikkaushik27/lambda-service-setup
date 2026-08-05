variable "function_name" {
  type = string
}

variable "runtime" {
  type = string
}

variable "handler" {
  type = string
}

variable "memory_size" {
  type = string
}

variable "timeout" {
  type = string
}

variable "lambda_role_arn" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "s3_bucket" {
  type = string
}

variable "s3_key" {
  type = string
}

variable "harness_account_id" {
  type = string
}

variable "harness_org_id" {
  type = string
}

variable "harness_project_id" {
  type = string
}

variable "github_connector_id" {
  type = string
}

variable "github_branch" {
  type = string
}

variable "aws_connector_id" {
  type = string
}

variable "harness_platform_api_key" {
  type      = string
  sensitive = true
}
