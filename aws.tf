data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# IAM execution role the Lambda function will run as.
# Created ahead of time so the Harness native AWS Lambda deploy step can
# reference a ready-made Role ARN in the function definition manifest.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------------------------------------------------------------------------
# S3 bucket that stores the Lambda deployment package. This is a one-time
# piece of infrastructure created directly by local `tofu apply` (NOT by the
# pipeline) - the bucket itself rarely changes, so there's no need to
# re-provision it on every pipeline run.
#
# The pipeline's CI stage uploads a fresh lambda.zip into this bucket on
# every run, and the IACM stage's Terraform run reads that object to create
# the actual aws_lambda_function.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "lambda_artifacts" {
  bucket        = "${var.function_name}-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "lambda_artifacts" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "lambda_artifacts" {
  bucket                  = aws_s3_bucket.lambda_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
