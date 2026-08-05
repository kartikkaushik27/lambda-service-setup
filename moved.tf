# Lets the environment/infrastructure resources follow their new module
# address instead of being destroyed and recreated.
#
# Safe to delete after the next successful apply.

moved {
  from = harness_platform_environment.this
  to   = module.environment.harness_platform_environment.this
}

moved {
  from = harness_platform_infrastructure.this
  to   = module.environment.harness_platform_infrastructure.this
}
