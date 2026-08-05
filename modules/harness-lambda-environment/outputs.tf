output "environment_id" {
  description = "Identifier of the Harness environment."
  value       = harness_platform_environment.this.identifier
}

output "infrastructure_id" {
  description = "Identifier of the AwsLambda infrastructure definition."
  value       = harness_platform_infrastructure.this.identifier
}
