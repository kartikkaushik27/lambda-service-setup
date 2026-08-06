output "function_name" {
  description = "Name of the deployed Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "Unqualified ARN of the deployed Lambda function."
  value       = aws_lambda_function.this.arn
}

output "qualified_arn" {
  description = "ARN including the published version, when publishing is enabled."
  value       = aws_lambda_function.this.qualified_arn
}

output "version" {
  description = "Published version of the function ($LATEST when publishing is disabled)."
  value       = aws_lambda_function.this.version
}
