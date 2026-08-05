output "service_id" {
  description = "Identifier of the Harness service."
  value       = harness_platform_service.this.identifier
}

output "service_yaml" {
  description = "Rendered service YAML, useful for debugging manifest/artifact wiring."
  value       = local.service_yaml
}
