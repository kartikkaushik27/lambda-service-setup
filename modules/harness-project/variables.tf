variable "org_id" {
  description = "Harness organization the project is created in."
  type        = string
}

variable "project_id" {
  description = "Identifier of the Harness project to create."
  type        = string
}

variable "project_name" {
  description = "Display name of the Harness project."
  type        = string
}

variable "project_color" {
  description = "Project colour shown in the Harness UI."
  type        = string
  default     = "#0063F7"
}

variable "project_tags" {
  description = "Harness tags applied to the project, in key:value form."
  type        = list(string)
  default     = []
}

variable "secret_manager_identifier" {
  description = "Secret manager that stores the secrets. Defaults to the Harness built-in manager."
  type        = string
  default     = "harnessSecretManager"
}

variable "aws_region" {
  description = "Default region for the AWS connector."
  type        = string
}

variable "aws_connector_identifier" {
  description = "Identifier of the AWS connector."
  type        = string
  default     = "aws_lambda_connector"
}

variable "aws_connector_name" {
  description = "Display name of the AWS connector."
  type        = string
  default     = "AWS Lambda Connector"
}

variable "github_connector_identifier" {
  description = "Identifier of the GitHub connector."
  type        = string
  default     = "github_connector"
}

variable "github_connector_name" {
  description = "Display name of the GitHub connector."
  type        = string
  default     = "GitHub Connector"
}

variable "github_owner" {
  description = "GitHub user or organization owning the repository."
  type        = string
}

variable "github_repo_name" {
  description = "Repository the GitHub connector is scoped to."
  type        = string
}

# ---------------------------------------------------------------------------
# Credentials
# ---------------------------------------------------------------------------

variable "aws_access_key_id" {
  description = "AWS access key id stored as a Harness secret."
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key stored as a Harness secret."
  type        = string
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS STS session token stored as a Harness secret."
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub personal access token stored as a Harness secret."
  type        = string
  sensitive   = true
}

variable "harness_platform_api_key" {
  description = "Harness platform API key stored as a secret for the IACM stage to authenticate with."
  type        = string
  sensitive   = true
}
