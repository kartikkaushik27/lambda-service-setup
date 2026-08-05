variable "function_name" {
  description = "Name of the Lambda function this foundation supports. Seeds the IAM role and log group names."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,64}$", var.function_name))
    error_message = "function_name must be 1-64 characters of letters, digits, hyphens or underscores."
  }
}

variable "artifact_bucket_name" {
  description = "Globally unique name for the S3 bucket that stores Lambda deployment packages."
  type        = string
}

variable "artifact_bucket_force_destroy" {
  description = "Allow deleting the artifact bucket while it still holds objects. Keep false outside throwaway environments."
  type        = bool
  default     = false
}

variable "artifact_retention_days" {
  description = "Days to keep non-current (superseded) deployment packages before expiring them."
  type        = number
  default     = 90

  validation {
    condition     = var.artifact_retention_days >= 1
    error_message = "artifact_retention_days must be at least 1."
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the function's log group."
  type        = number
  default     = 30

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.log_retention_days
    )
    error_message = "log_retention_days must be a retention period CloudWatch Logs accepts (e.g. 1, 7, 30, 90, 365)."
  }
}

variable "additional_policy_arns" {
  description = "Extra managed policy ARNs to attach to the execution role (e.g. for DynamoDB or SQS access)."
  type        = list(string)
  default     = []
}

variable "max_session_duration" {
  description = "Maximum session duration (seconds) for the execution role."
  type        = number
  default     = 3600
}
