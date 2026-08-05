# Every input is supplied by config.auto.tfvars. Related values are grouped
# into objects so the interface stays small and a new setting is added in one
# place rather than as another loose variable.
#
# There is deliberately no credential variable here: the AWS and Harness
# providers read theirs from the environment, so a credential can never end up
# in a plan file.

variable "aws_region" {
  description = "Region the function and artifact bucket live in."
  type        = string
}

variable "function" {
  description = "Definition of the Lambda function to deploy."

  type = object({
    name                  = string
    runtime               = string
    handler               = string
    timeout               = number
    memory_size           = number
    execution_role_arn    = string
    architecture          = optional(string, "x86_64")
    publish_version       = optional(bool, true)
    environment_variables = optional(map(string), {})
  })
}

variable "artifact" {
  description = "Location of the deployment package published by the CI stage. service_file_path is what the Harness service deploys - \"<+input>\" leaves it a runtime input the pipeline supplies per execution."

  type = object({
    bucket            = string
    key               = string
    service_file_path = optional(string, "<+input>")
  })
}

variable "harness" {
  description = "Harness scope, connectors and identifiers the service entity is built from."

  type = object({
    org_id                     = string
    project_id                 = string
    aws_connector_id           = string
    github_connector_id        = string
    github_branch              = string
    function_definition_path   = optional(string, "harness/function-definition.json")
    service_identifier         = optional(string, "lambda_service")
    artifact_source_identifier = optional(string, "awslambdaartifact")
  })
}

variable "tags" {
  description = "Tags applied to every AWS resource created here."
  type        = map(string)
  default     = {}
}
