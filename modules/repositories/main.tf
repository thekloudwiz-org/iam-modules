resource "github_repository" "repos" {
  for_each = var.repositories

  name        = each.key
  description = each.value.description
  visibility  = each.value.visibility

  has_issues   = true
  has_projects = false
  has_wiki     = false

  auto_init              = true
  delete_branch_on_merge = true
  allow_merge_commit     = true
  allow_rebase_merge     = true
  allow_squash_merge     = true

  topics = each.value.topics
}

# Create dev branch for each repository
resource "github_branch" "dev" {
  for_each = {
    for k, v in var.repositories : k => v
    if v.has_dev_environment
  }

  repository    = github_repository.repos[each.key].name
  branch        = "dev"
  source_branch = "main"
  
  depends_on = [github_repository.repos]
}

# Create environments for each repository
resource "github_repository_environment" "environments" {
  for_each = {
    for env in local.repo_environments : "${env.repo_name}.${env.env_name}" => env
  }

  repository  = each.value.repo_name
  environment = each.value.env_name

  # For dev environment, don't use any branch protection policy
  # This allows any branch to deploy to dev environment
  dynamic "deployment_branch_policy" {
    for_each = each.value.env_name == "dev" ? [] : [1]
    content {
      protected_branches     = true
      custom_branch_policies = false
    }
  }
  
  # Simple dependency on both repository and dev branch
  depends_on = [
    github_repository.repos,
    github_branch.dev
  ]
}

# Branch Protection for main branch
resource "github_branch_protection" "main" {
  for_each = var.repositories

  repository_id = github_repository.repos[each.key].node_id
  pattern       = "main"

  enforce_admins = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }
  
  depends_on = [github_repository.repos]
}

# Branch Protection for dev branch
resource "github_branch_protection" "dev" {
  for_each = {
    for k, v in var.repositories : k => v
    if v.has_dev_environment
  }

  repository_id = github_repository.repos[each.key].node_id
  pattern       = "dev"

  enforce_admins = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 1
    require_code_owner_reviews      = lookup(each.value, "require_code_owner_reviews", false)
  }
  
  depends_on = [github_repository.repos, github_branch.dev]
}