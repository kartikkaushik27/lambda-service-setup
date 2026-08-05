# harness-lambda-environment

The deployment target for Harness-native AWS Lambda deployments: an
environment plus an `AwsLambda` infrastructure definition naming the AWS
connector and region to deploy into.

Required by the `AwsLambdaDeploy` step - a Deployment stage cannot run without
an environment and infrastructure to deploy to. Applied from the root
configuration, since neither changes between deployments.

## Usage

```hcl
module "harness_lambda_environment" {
  source = "./modules/harness-lambda-environment"

  org_id     = "default"
  project_id = module.harness_project.project_id

  aws_connector_id = module.harness_project.aws_connector_id
  aws_region       = "us-east-1"
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `org_id` / `project_id` | string | – | Harness scope |
| `environment_identifier` / `environment_name` | string | `dev` | Environment identity |
| `environment_type` | string | `PreProduction` | `PreProduction` or `Production` |
| `infrastructure_identifier` / `infrastructure_name` | string | `lambda_infra` / `lambda-infra` | Infrastructure identity |
| `aws_connector_id` | string | – | Connector the deploy step authenticates with |
| `aws_region` | string | – | Region to deploy into |

## Outputs

`environment_id`, `infrastructure_id`.

## Note on delegates

Unlike the CI and IACM stages, which run on Harness Cloud, the native
`AwsLambdaDeploy` step executes on a delegate. A healthy delegate with access
to this AWS connector must be running for the Deployment stage to succeed.
