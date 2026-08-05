# module.lambda and module.service became for_each maps to support multiple
# lambdas per project. The original project's tfvars keeps the map key
# "lambda_service" so this follows the existing resources to their new
# address instead of destroying and recreating them.
#
# Safe to delete after the next successful apply of every workspace using
# this configuration.

moved {
  from = module.lambda
  to   = module.lambda["lambda_service"]
}

moved {
  from = module.service
  to   = module.service["lambda_service"]
}
