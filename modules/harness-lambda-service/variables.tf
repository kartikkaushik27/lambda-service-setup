variable "service_identifier" {
  description = "Harness identifier for the service."
  type        = string
  default     = "lambda_service"
}

variable "service_name" {
  description = "Display name for the Harness service."
  type        = string
}

variable "org_id" {
  description = "Harness organization identifier."
  type        = string
}

variable "project_id" {
  description = "Harness project identifier."
  type        = string
}

variable "github_connector_id" {
  description = "Harness GitHub connector used to fetch the function definition manifest."
  type        = string
}

variable "github_branch" {
  description = "Branch to fetch the function definition manifest from."
  type        = string
}

variable "function_definition_path" {
  description = "Repo-relative path of the AWS Lambda function definition manifest."
  type        = string
  default     = "harness/function-definition.json"
}

variable "aws_connector_id" {
  description = "Harness AWS connector used to read the deployment package from S3."
  type        = string
}

variable "aws_region" {
  description = "Region the artifact bucket lives in."
  type        = string
}

variable "artifact_bucket" {
  description = "S3 bucket holding the deployment package."
  type        = string
}

variable "artifact_source_identifier" {
  description = "Identifier of the primary artifact source. The pipeline must use the same value when supplying service inputs."
  type        = string
  default     = "awslambdaartifact"
}

variable "artifact_file_path" {
  description = "S3 key the service deploys. Keep the default \"<+input>\" to make it a runtime input the pipeline supplies at deploy time, or set a literal key to pin the service to one package."
  type        = string
  default     = "<+input>"
}
