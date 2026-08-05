variable "function_name" {
  description = "Name of the Lambda function to create or update."
  type        = string
}

variable "description" {
  description = "Description shown on the function in the AWS console."
  type        = string
  default     = "Managed by OpenTofu via Harness IACM"
}

variable "execution_role_arn" {
  description = "ARN of the IAM role the function assumes at runtime (see the lambda-foundation module)."
  type        = string
}

variable "artifact_bucket" {
  description = "S3 bucket holding the deployment package."
  type        = string
}

variable "artifact_key" {
  description = "S3 key of the deployment package uploaded by the CI stage."
  type        = string
}

variable "runtime" {
  description = "Lambda runtime identifier, e.g. nodejs20.x."
  type        = string

  validation {
    condition     = can(regex("^(nodejs|python|java|dotnet|ruby|provided)", var.runtime))
    error_message = "runtime must be a supported AWS Lambda runtime family (nodejs*, python*, java*, dotnet*, ruby*, provided*)."
  }
}

variable "handler" {
  description = "Function entry point, e.g. index.handler."
  type        = string
}

variable "timeout" {
  description = "Execution timeout in seconds."
  type        = number

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900 seconds."
  }
}

variable "memory_size" {
  description = "Memory allocated to the function, in MB."
  type        = number

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240 MB."
  }
}

variable "architecture" {
  description = "Instruction set the function runs on."
  type        = string
  default     = "x86_64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "architecture must be x86_64 or arm64."
  }
}

variable "environment_variables" {
  description = "Environment variables exposed to the function at runtime."
  type        = map(string)
  default     = {}
}

variable "publish_version" {
  description = "Publish an immutable numbered version on each code change, enabling rollback to a previous build."
  type        = bool
  default     = true
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency for the function. -1 leaves it drawing from the unreserved account pool."
  type        = number
  default     = -1
}

variable "tracing_mode" {
  description = "X-Ray tracing mode. Active requires X-Ray write permissions on the execution role."
  type        = string
  default     = "PassThrough"

  validation {
    condition     = contains(["PassThrough", "Active"], var.tracing_mode)
    error_message = "tracing_mode must be PassThrough or Active."
  }
}
