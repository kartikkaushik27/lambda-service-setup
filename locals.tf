# Shared computed values referenced from multiple .tf files (the pipeline
# YAML, the IACM workspace variables, and outputs.tf).

locals {
  # Fixed S3 key the CI stage always uploads the freshly-built Lambda zip to,
  # and the key the IACM stage's Terraform run reads to create/update the
  # aws_lambda_function. Kept as a single well-known path (no per-build
  # suffix) so the flow stays simple to reason about.
  lambda_artifact_key = "${var.function_name}/lambda.zip"
}
