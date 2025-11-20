# org_name   = "thekloudwiz-org"
github_org = "thekloudwiz-org"
project_name = "thekloudwiz"
aws_region   = "eu-central-1"
owner = "thekloudwiz-org"
# environment  = "global"

# Organization members
org_admins = [
  "kloudwiz"
]  
org_members = ["wizreviewer"]
org_blocked_users = []

# GitHub teams
github_teams = {
  "developers" = {
    description = "Team for developers"
    privacy     = "closed"
    members     = ["wizreviewer"]
    maintainers = ["kloudwiz"]
    admin_repositories    = ["fullstack-todo-task"]
    maintain_repositories = []
    push_repositories     = []
    triage_repositories   = []
    pull_repositories     = []
  },
  "devops" = {
    description = "Team for DevOps engineers"
    privacy     = "closed"
    members     = ["wizreviewer"]
    maintainers = ["kloudwiz"]
    admin_repositories    = ["fullstack-todo-task"]
    maintain_repositories = []
    push_repositories     = []
    triage_repositories   = []
    pull_repositories     = []
  }
}

# GitHub repositories configuration
repositories = {
  "fullstack-todo-task" = {
    description         = "Test repository with multiple environments"
    has_dev_environment = true
    environments        = ["dev", "stg", "qa", "prd"]
    topics              = ["development", "terraform", "testing"]
    visibility          = "public"
    code_owners         = ["kloudwiz", "developers", "devops", "wizreviewer"]
    require_code_owner_reviews = true
  }
  # "test-repo-200625" = {
  #   description         = "Test repository with multiple environments"
  #   has_dev_environment = true
  #   environments        = ["dev", "stg", "qa", "prd"]
  #   topics              = ["development", "terraform", "testing"]
  #   visibility          = "public"
  # }
}