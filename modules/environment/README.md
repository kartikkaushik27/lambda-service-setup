# environment

Creates a Harness Environment and its `AwsLambda` Infrastructure Definition -
the deployment target a native `AwsLambdaDeploy` step requires.

One instance is one (environment name, region) deployment target.

## Usage

```hcl
module "environment" {
  source = "../modules/environment"

  org_id     = "default"
  project_id = "lambda_service_poc"

  environment_identifier = "orders_service_dev"
  environment_name       = "dev"
  environment_type       = "PreProduction"

  infra_identifier = "orders_service_dev_us_east_1"
  infra_name       = "orders-service-dev-us-east-1"

  aws_connector_id = "aws_lambda_connector"
  aws_region       = "us-east-1"
}
```

## Why identifiers are scoped by caller

A Harness environment/infrastructure identifier only has to be unique within
a project, not globally. The root config uses this module once for the
original project. `iacm/` calls it once per self-service project, scoped by
project name, so two projects deployed to the same environment name and
region never collide on identifier - see `iacm/main.tf`.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `org_id` / `project_id` | string | – | Harness scope |
| `environment_identifier` / `environment_name` | string | – | Environment identity |
| `environment_type` | string | `PreProduction` | `PreProduction` or `Production` |
| `infra_identifier` / `infra_name` | string | – | Infrastructure definition identity |
| `aws_connector_id` | string | – | Existing Harness AWS connector |
| `aws_region` | string | – | Region this deployment target's functions live in |

## Outputs

`environment_id`, `infrastructure_id`.
