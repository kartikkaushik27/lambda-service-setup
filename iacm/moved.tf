# The state behind this configuration is owned by the Harness IACM workspace,
# so there is no local CLI to run `state mv` against. These blocks let the next
# pipeline run adopt the addresses the resources moved to when this directory
# was refactored into modules - without them, that run would destroy the live
# function and its service and create them again.
#
# Safe to delete after one successful apply.

moved {
  from = aws_lambda_function.this
  to   = module.lambda_function.aws_lambda_function.this
}

moved {
  from = harness_platform_service.this
  to   = module.harness_lambda_service.harness_platform_service.this
}
