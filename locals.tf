locals {
  # Applied to every AWS resource through the provider's default_tags, and
  # forwarded to the IACM configuration so resources created by the pipeline
  # carry the same tags as those created here.
  common_tags = merge(
    {
      Application = var.function_name
      Environment = var.environment
      Owner       = var.owner
      ManagedBy   = "OpenTofu"
      Repository  = "${var.github_owner}/${var.github_repo_name}"
    },
    var.additional_tags,
  )

  artifact_bucket_name = "${var.function_name}-artifacts-${data.aws_caller_identity.current.account_id}"

  # One well-known key that every build overwrites. The bucket is versioned, so
  # each upload is still a distinct object version - that version id is what
  # the IACM stage uses to detect new code (see modules/lambda-function).
  artifact_key = "${var.function_name}/lambda.zip"

  # Immutable per-build packages live under here as <build number>.zip. The
  # native deploy stage deploys one of these by name, passed to the service as
  # a runtime input, so a release points at a specific build.
  artifact_build_prefix = "${var.function_name}/builds"

  # The service is created by the IACM stage, but the pipeline (created here)
  # has to reference it, so the identifiers are fixed in one place and shared
  # with iacm/ through the generated tfvars.
  service_identifier         = "lambda_service"
  artifact_source_identifier = "awslambdaartifact"

  # Repo-relative path of the manifest generated below and read by the Harness
  # service at deploy time.
  function_definition_path = "harness/function-definition.json"
}
