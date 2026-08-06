# One of these per self-service project. The filename (minus .tfvars) is the
# project name - "demo-project.tfvars" here means project_name="demo-project"
# below must match it.
#
# Lambdas are NOT declared here - they're auto-discovered from
# lambda-src/demo-project/* directories every pipeline run (see
# iacm/variables.tf: lambda_names). Add a new lambda-src/demo-project/<name>
# directory (with a matching harness/demo-project/<name>/<region>/
# function-definition.json manifest) to add a lambda; delete the directory
# to stop managing it. No file here needs to change either way.
#
# Pushing a change under lambda-src/demo-project/** (or this file) to
# dev/test/stage/prod is the entire deploy workflow:
#   - dev                -> a workspace in us-east-1
#   - test, stage, prod  -> a workspace in us-east-1 AND one in us-west-1
#
# Only lambda-src/<project>/<lambda> directories that actually changed (or
# have never been deployed) get rebuilt and redeployed - see README.md.

project_name = "demo-project"

harness = {
  org_id              = "default"
  project_id          = "lambda_service_poc"
  github_connector_id = "github_connector"
  aws_connector_id    = "aws_lambda_connector"
}

# AWS requires a Lambda's S3 source to be in the same region as the
# function, so every region this project is deployed to needs an entry here.
artifact_buckets = {
  "us-east-1" = "lambda-service-poc-artifacts-915632791698"
  "us-west-1" = "lambda-service-poc-artifacts-915632791698-us-west-1"
}

tags = {
  "Application" = "demo-project"
  "ManagedBy"   = "OpenTofu"
  "Owner"       = "platform-engineering"
}
