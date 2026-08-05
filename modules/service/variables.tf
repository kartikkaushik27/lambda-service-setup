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
  description = "Existing Harness GitHub connector used to fetch the function definition manifest."
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

variable "artifact_source_identifier" {
  description = "Identifier of the primary artifact source. The pipeline uses the same value when supplying its runtime inputs."
  type        = string
  default     = "lambda_artifact"
}

variable "artifact_source_type" {
  description = "Kind of artifact store the package is pulled from, e.g. AmazonS3, ArtifactoryRegistry, DockerRegistry. Its location is supplied per execution as runtime inputs, so only the type is fixed here."
  type        = string
  default     = "AmazonS3"
}
