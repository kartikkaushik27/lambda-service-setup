output "execution_role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.this.arn
}

output "execution_role_name" {
  description = "Name of the Lambda execution role."
  value       = aws_iam_role.this.name
}

output "artifact_bucket" {
  description = "Name of the S3 bucket holding Lambda deployment packages."
  value       = aws_s3_bucket.artifacts.id
}

output "artifact_bucket_arn" {
  description = "ARN of the S3 bucket holding Lambda deployment packages."
  value       = aws_s3_bucket.artifacts.arn
}

output "log_group_name" {
  description = "CloudWatch Logs group the function writes to."
  value       = aws_cloudwatch_log_group.lambda.name
}
