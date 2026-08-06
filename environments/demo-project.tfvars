# One of these per self-service project. The filename (minus .tfvars) is the
# project name - "demo-project.tfvars" here means project_name="demo-project"
# below must match it.
#
# Pushing this file (or a change under lambda-src/demo-project/**) to
# dev/test/stage/prod is the entire deploy workflow:
#   - dev                -> a workspace in us-east-1
#   - test, stage, prod  -> a workspace in us-east-1 AND one in us-west-1
#
# Only lambda-src/<project>/<lambda> directories that actually changed (or
# have never been deployed) get rebuilt and redeployed - see README.md.
#
# artifact_by_region is the only thing a lambda needs here. The function
# itself - role, runtime, handler, memory, tags - is defined by its committed
# harness/<project>/<lambda>/<region>/function-definition.json, which the
# native deploy step creates or updates the function from. Terraform never
# touches the function.

project_name = "demo-project"

harness = {
  org_id              = "default"
  project_id          = "lambda_service_poc"
  github_connector_id = "github_connector"
  aws_connector_id    = "aws_lambda_connector"
}

# Add another entry here to deploy another function from this project - and
# a matching harness/demo-project/<key>/<region>/function-definition.json.
lambdas = {
  api = {
    # AWS requires a Lambda's S3 source to be in the same region as the
    # function, so add an entry here for every region this file is deployed
    # to (us-east-1 always; add us-west-1 too before pushing to
    # test/stage/prod).
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
  }

  worker = {
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
  }

  notifier = {
    artifact_by_region = {
      "us-east-1" = {
        bucket = "lambda-service-poc-artifacts-915632791698"
        key    = "demo-project/notifier/lambda.zip"
      }
      "us-west-1" = {
        bucket = "lambda-service-poc-artifacts-915632791698-us-west-1"
        key    = "demo-project/notifier/lambda.zip"
      }
    }
  }

  scheduler = {
    artifact_by_region = {
      "us-east-1" = {
        bucket = "lambda-service-poc-artifacts-915632791698"
        key    = "demo-project/scheduler/lambda.zip"
      }
      "us-west-1" = {
        bucket = "lambda-service-poc-artifacts-915632791698-us-west-1"
        key    = "demo-project/scheduler/lambda.zip"
      }
    }
  }
}

tags = {
  "Application" = "demo-project"
  "ManagedBy"   = "OpenTofu"
  "Owner"       = "platform-engineering"
}
