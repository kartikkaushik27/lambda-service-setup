# Records where resources went when this configuration was split into modules,
# so state follows the refactor instead of the next apply destroying and
# recreating everything under its new address.
#
# Safe to delete once every environment that shares this state has applied it
# at least once. Harmless in a fresh state, where the old addresses never
# existed.

moved {
  from = aws_iam_role.lambda_exec
  to   = module.lambda_foundation.aws_iam_role.this
}

moved {
  from = aws_iam_role_policy_attachment.lambda_basic_execution
  to   = module.lambda_foundation.aws_iam_role_policy_attachment.basic_execution
}

moved {
  from = aws_s3_bucket.lambda_artifacts
  to   = module.lambda_foundation.aws_s3_bucket.artifacts
}

moved {
  from = aws_s3_bucket_versioning.lambda_artifacts
  to   = module.lambda_foundation.aws_s3_bucket_versioning.artifacts
}

moved {
  from = aws_s3_bucket_public_access_block.lambda_artifacts
  to   = module.lambda_foundation.aws_s3_bucket_public_access_block.artifacts
}

moved {
  from = harness_platform_project.this
  to   = module.harness_project.harness_platform_project.this
}

moved {
  from = harness_platform_secret_text.aws_access_key_id
  to   = module.harness_project.harness_platform_secret_text.aws_access_key_id
}

moved {
  from = harness_platform_secret_text.aws_secret_access_key
  to   = module.harness_project.harness_platform_secret_text.aws_secret_access_key
}

moved {
  from = harness_platform_secret_text.aws_session_token
  to   = module.harness_project.harness_platform_secret_text.aws_session_token
}

moved {
  from = harness_platform_secret_text.github_pat
  to   = module.harness_project.harness_platform_secret_text.github_pat
}

moved {
  from = harness_platform_secret_text.harness_pat
  to   = module.harness_project.harness_platform_secret_text.harness_pat
}

moved {
  from = harness_platform_connector_aws.this
  to   = module.harness_project.harness_platform_connector_aws.this
}

moved {
  from = harness_platform_connector_github.this
  to   = module.harness_project.harness_platform_connector_github.this
}

moved {
  from = harness_platform_workspace.lambda
  to   = module.harness_iacm_workspace.harness_platform_workspace.this
}

moved {
  from = harness_platform_pipeline.this
  to   = module.harness_lambda_pipeline.harness_platform_pipeline.this
}
