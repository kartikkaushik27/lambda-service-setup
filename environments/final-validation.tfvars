# See environments/demo-project.tfvars for the full explanation of this
# schema. Lambdas are auto-discovered from lambda-src/final-validation/*.

project_name = "final-validation"

harness = {
  org_id              = "default"
  project_id          = "lambda_service_poc"
  github_connector_id = "github_connector"
  aws_connector_id    = "aws_lambda_connector"
}

artifact_buckets = {
  "us-east-1" = "lambda-service-poc-artifacts-915632791698"
  "us-west-1" = "lambda-service-poc-artifacts-915632791698-us-west-1"
}

tags = {
  "Application" = "final-validation"
  "ManagedBy"   = "OpenTofu"
  "Owner"       = "platform-engineering"
}

