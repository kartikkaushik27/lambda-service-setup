# One of these per self-service project. The filename (minus .tfvars) is the
# project name - "demo-project.tfvars" here means project_name="demo-project"
# below must match it, and the Create Environment Workspaces pipeline names
# every workspace it creates from this file after it too.
#
# Pushing this file to dev/test/stage/prod is the entire deploy workflow:
#   - dev                -> a workspace in us-east-1
#   - test, stage, prod  -> a workspace in us-east-1 AND one in us-west-1
#
# region and environment_name are NOT declared here - they're set on each
# workspace individually by the pipeline that creates it, since this same
# file is reused by every region/environment workspace for this project. See
# iacm/variables.tf for the full schema.

project_name = "demo-project"

harness = {
  org_id              = "default"
  project_id          = "lambda_service_poc"
  github_connector_id = "github_connector"
  github_branch       = "main" # branch iacm/ itself is read from - independent of which branch owns this workspace
  aws_connector_id    = "aws_lambda_connector"
}

# Add another entry here to deploy another function from this project, in
# every region/environment this file is already active in.
lambdas = {
  api = {
    runtime            = "nodejs20.x"
    handler            = "index.handler"
    timeout            = 10
    memory_size        = 128
    execution_role_arn = "arn:aws:iam::915632791698:role/demo-project-api-exec-role"

    # AWS requires a Lambda's S3 source to be in the same region as the
    # function, so a build published for this project needs an entry here
    # for every region this file is deployed to (us-east-1 always; add
    # us-west-1 too before pushing this file to test/stage/prod).
    artifact_by_region = {
      "us-east-1" = {
        bucket = "lambda-service-poc-artifacts-915632791698"
        key    = "demo-project/api/lambda.zip"
      }
      "us-west-1" = {
        bucket = "lambda-service-poc-artifacts-915632791698-us-west-1"
        key    = "demo-project/api/lambda.zip"
      }
    }

    # Paired manifest committed at harness/demo-project/api/function-definition.json
  }

  worker = {
    runtime            = "nodejs20.x"
    handler            = "index.handler"
    timeout            = 10
    memory_size        = 128
    execution_role_arn = "arn:aws:iam::915632791698:role/demo-project-api-exec-role"

    artifact_by_region = {
      "us-east-1" = {
        bucket = "lambda-service-poc-artifacts-915632791698"
        key    = "demo-project/worker/lambda.zip"
      }
      "us-west-1" = {
        bucket = "lambda-service-poc-artifacts-915632791698-us-west-1"
        key    = "demo-project/worker/lambda.zip"
      }
    }

    # Paired manifest committed at harness/demo-project/worker/function-definition.json
  }
}

tags = {
  "Application" = "demo-project-api"
  "ManagedBy"   = "OpenTofu"
  "Owner"       = "platform-engineering"
}
