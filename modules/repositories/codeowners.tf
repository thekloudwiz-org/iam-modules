resource "github_repository_file" "codeowners" {
  for_each = {
    for repo_name, repo in var.repositories : repo_name => repo
    if lookup(repo, "create_codeowners", false)
  }

  repository          = github_repository.repos[each.key].name
  branch              = "main"
  file                = ".github/CODEOWNERS"
  content             = templatefile(
    "${path.module}/templates/CODEOWNERS.tpl",
    {
      default_owners = lookup(each.value, "default_owners", [])
      path_owners    = lookup(each.value, "path_owners", {})
    }
  )
  commit_message      = "Add CODEOWNERS file"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true

  depends_on = [github_repository.repos]
}

# Create pull request template
resource "github_repository_file" "pr_template" {
  for_each = {
    for repo_name, repo in var.repositories : repo_name => repo
    if lookup(repo, "create_pr_template", false)
  }

  repository          = github_repository.repos[each.key].name
  branch              = "main"
  file                = ".github/PULL_REQUEST_TEMPLATE.md"
  content             = templatefile(
    "${path.module}/templates/PULL_REQUEST_TEMPLATE.md.tpl",
    {
      project_name = each.key
    }
  )
  commit_message      = "Add pull request template"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true

  depends_on = [github_repository.repos]
}