output "pipeline_id" {
  description = "Identifier of the pipeline."
  value       = harness_platform_pipeline.this.identifier
}

output "pipeline_yaml" {
  description = "Rendered pipeline YAML, useful for reviewing a change before applying it."
  value       = local.pipeline_yaml
}
