# org_name   = "thekloudwiz-org"
github_org      = "thekloudwiz-org"
project_name    = "thekloudwiz"
aws_region      = "eu-central-1"
owner           = "thekloudwiz-org"
is_organization = true
# environment  = "global"

# Organization members
org_admins = [
  "kloudwiz"
]
org_members       = ["wizreviewer"]
org_blocked_users = []

# GitHub teams
github_teams = {
  "developers" = {
    description           = "Team for developers"
    privacy               = "closed"
    members               = ["wizreviewer"]
    maintainers           = ["kloudwiz"]
    admin_repositories    = ["project-ecovolt", "project-kakraba", "iam-modules", "gyaale", "gyaale-pos-android", "akyeba", "portfolio"]
    maintain_repositories = []
    push_repositories     = []
    triage_repositories   = []
    pull_repositories     = []
  },
  "devops" = {
    description           = "Team for DevOps engineers"
    privacy               = "closed"
    members               = ["wizreviewer"]
    maintainers           = ["kloudwiz"]
    admin_repositories    = ["project-ecovolt", "project-kakraba", "iam-modules", "gyaale", "gyaale-pos-android", "akyeba", "portfolio"]
    maintain_repositories = []
    push_repositories     = []
    triage_repositories   = []
    pull_repositories     = []
  },
  "analysts" = {
    description           = "Team for Analysts engineers"
    privacy               = "closed"
    members               = ["wizreviewer"]
    maintainers           = ["kloudwiz"]
    admin_repositories    = ["project-ecovolt", "project-kakraba", "iam-modules", "gyaale", "gyaale-pos-android", "akyeba", "portfolio"]
    maintain_repositories = []
    push_repositories     = []
    triage_repositories   = []
    pull_repositories     = []
  }
}

# GitHub repositories configuration
repositories = {
  "project-ecovolt" = {
    description         = "Test repository with multiple environments"
    has_dev_environment = true
    environments        = ["dev", "stg", "qa", "prd"]
    topics              = ["development", "terraform", "testing"]
    visibility          = "public"
    code_owners         = ["kloudwiz", "developers", "devops", "wizreviewer"]
  },
  "project-kakraba" = {
    description         = "A fully serverless AWS-powered platform enabling creators to upload, manage, and monetize digital content with secure streaming, paywall logic, and automated distribution."
    has_dev_environment = true
    environments        = ["dev", "stg", "qa", "prd"]
    topics              = ["development", "terraform", "testing"]
    visibility          = "public"
    code_owners         = ["kloudwiz", "developers", "devops", "wizreviewer"]
  },
  "gyaale" = {
    description         = "A serverless food ordering and event booking platform with online payments, real-time order processing, and an admin dashboard for business insights."
    has_dev_environment = true
    environments        = ["dev", "stg", "qa", "prd"]
    topics              = ["serverless", "aws", "terraform", "dynamodb", "api-gateway", "lambda", "cloudfront", "tailwindcss", "paystack", "food-ordering", "ci-cd"]
    visibility          = "private"
    code_owners         = ["kloudwiz", "developers", "devops", "wizreviewer"]
  },
  "gyaale-pos-android" = {
    description         = "Gyaale POS Android application"
    has_dev_environment = true
    environments        = ["dev", "stg", "qa", "prd"]
    topics              = ["android", "pos", "mobile"]
    visibility          = "private"
    code_owners         = ["kloudwiz", "developers", "devops", "wizreviewer"]
  },
  "akyeba" = {
    description            = "Akyeba website"
    has_dev_environment    = true
    environments           = ["dev", "stg", "qa", "prd"]
    topics                 = ["web"]
    visibility             = "private"
    code_owners            = ["kloudwiz", "developers", "devops", "wizreviewer"]
    required_status_checks = []
  },

  "portfolio" = {
    description         = "TheKloudWiz brand + portfolio site at thekloudwiz.com — the top-of-funnel hub above the product marketing sites, showcasing each product with a link-out to its own landing page."
    has_dev_environment = true
    environments        = ["dev", "stg", "qa", "prd"]
    topics              = ["web", "portfolio", "static-site", "aws", "cloudfront"]
    visibility          = "private"
    code_owners         = ["kloudwiz", "developers", "devops", "wizreviewer"]
  }
}