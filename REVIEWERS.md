# Adding Team Members as Reviewers

This document explains how to add team members as reviewers to your GitHub repositories using this Terraform module.

## Method 1: Using CODEOWNERS

The CODEOWNERS file is a special file that defines who owns specific parts of the codebase. When someone opens a pull request that modifies code that has an owner, those owners are automatically requested for review.

### Step 1: Update your repository configuration

```hcl
module "github_repos" {
  source = "./modules/repositories"
  
  # Other configuration...
  
  repositories = {
    "your-repository-name" = {
      description         = "Repository description"
      has_dev_environment = true
      environments        = ["dev", "qa", "staging", "prod"]
      topics              = ["terraform", "aws"]
      visibility          = "private"
      
      # Add code owners who will be automatically requested for review
      code_owners = ["username1", "username2", "team-name"]
      
      # Require code owner approval for PRs
      require_code_owner_reviews = true
    }
  }
}
```

### Step 2: Create and manage teams

```hcl
module "dev_team" {
  source = "./modules/teams"

  name        = "developers"
  description = "Development team"
  privacy     = "closed"
  
  # Team members
  members = ["member1", "member2", "member3"]
  
  # Team maintainers (have admin rights on the team)
  maintainers = ["teamlead1", "teamlead2"]
  
  # Give the team push access to repositories
  push_repositories = ["your-repository-name"]
  
  module_enabled = true
}
```

## Method 2: Branch Protection Rules

You can also configure branch protection rules to require a specific number of reviews before merging:

```hcl
resource "github_branch_protection" "main" {
  repository_id = github_repository.your_repo.node_id
  pattern       = "main"

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 2
  }
}
```

## Method 3: Using GitHub Teams as Reviewers

When you create a team and assign it to a repository, you can then add the team as a reviewer in pull requests:

1. Create the team as shown in Method 2
2. When creating a pull request, add the team using `@team-name` in the reviewers section

## Implementation in Your Infrastructure Code

To implement these changes in your infrastructure code:

1. Update the repositories module to include code_owners and require_code_owner_reviews fields
2. Create or update teams with the appropriate members
3. Apply the Terraform configuration to update your GitHub repositories

After applying these changes, when someone opens a pull request, the specified code owners will be automatically requested for review.