# The repository this OpenTofu code itself lives in and gets pushed to.
# Created empty (auto_init = false) so a plain `git push` of the local
# working copy becomes the initial commit - avoiding any merge conflicts
# with a GitHub-generated initial commit.

resource "github_repository" "this" {
  name        = var.github_repo_name
  description = "OpenTofu-managed AWS Lambda function + Harness native AWS Lambda service/pipeline setup"
  visibility  = "private"
  auto_init   = false

  has_issues   = true
  has_projects = false
  has_wiki     = false
}
