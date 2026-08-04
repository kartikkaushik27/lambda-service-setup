resource "harness_platform_project" "this" {
  identifier = var.harness_project_id
  name       = var.harness_project_name
  org_id     = var.harness_org_id
  color      = "#0063F7"
  tags       = ["purpose:lambda-poc"]
}
