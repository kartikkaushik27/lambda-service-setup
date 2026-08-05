variable "identifier" {
  description = "Identifier of the IACM workspace."
  type        = string
}

variable "name" {
  description = "Display name of the IACM workspace."
  type        = string
}

variable "description" {
  description = "Description shown on the workspace."
  type        = string
  default     = "Provisions the Lambda function and its Harness service."
}

variable "org_id" {
  description = "Harness organization identifier."
  type        = string
}

variable "project_id" {
  description = "Harness project identifier."
  type        = string
}

variable "provisioner_type" {
  description = "IaC tool the workspace runs."
  type        = string
  default     = "opentofu"

  validation {
    condition     = contains(["opentofu", "terraform", "terragrunt"], var.provisioner_type)
    error_message = "provisioner_type must be opentofu, terraform or terragrunt."
  }
}

variable "provisioner_version" {
  description = "Provisioner version to run. \"latest\" tracks whatever Harness ships; pin an exact version once you have confirmed it is available to your account."
  type        = string
  default     = "latest"
}

variable "repository" {
  description = "HTTPS URL of the repository holding the configuration."
  type        = string
}

variable "repository_branch" {
  description = "Branch the workspace checks out."
  type        = string
}

variable "repository_path" {
  description = "Directory within the repository to run from."
  type        = string
}

variable "repository_connector" {
  description = "Harness Git connector used to clone the repository."
  type        = string
}

variable "cost_estimation_enabled" {
  description = "Show cost estimates alongside plans. Requires cost estimation to be available to the account."
  type        = bool
  default     = true
}

variable "harness_account_id" {
  description = "Harness account id, exported to runs as HARNESS_ACCOUNT_ID."
  type        = string
}

variable "aws_region" {
  description = "Default AWS region, exported to runs as AWS_DEFAULT_REGION."
  type        = string
}

variable "variable_set_identifier" {
  description = "Identifier of the credentials variable set this module creates."
  type        = string
  default     = "iacm_credentials"
}

variable "variable_set_name" {
  description = "Display name of the credentials variable set."
  type        = string
  default     = "IACM Credentials"
}

variable "credential_secret_ids" {
  description = "Identifiers of existing Harness secrets holding the credentials IACM runs authenticate with."
  type = object({
    aws_access_key_id        = string
    aws_secret_access_key    = string
    aws_session_token        = string
    harness_platform_api_key = string
  })
}

variable "additional_variable_set_ids" {
  description = "Further variable sets to attach, for inputs owned outside this stack."
  type        = list(string)
  default     = []
}
