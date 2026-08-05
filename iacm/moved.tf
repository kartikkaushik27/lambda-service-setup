# The state behind this configuration is owned by the Harness IACM workspace,
# so there is no local CLI to run `state mv` against. These blocks let the next
# pipeline run follow the modules to their current names instead of destroying
# the live function and service and creating them again.
#
# Safe to delete after one successful apply.

moved {
  from = module.lambda_function.aws_lambda_function.this
  to   = module.lambda.aws_lambda_function.this
}

moved {
  from = module.harness_lambda_service.harness_platform_service.this
  to   = module.service.harness_platform_service.this
}
