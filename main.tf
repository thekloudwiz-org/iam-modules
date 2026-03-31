# IAM Modules - Main Configuration

# GitHub Organization - Manage organization members and teams
module "organization" {
  source = "./modules/organization"

  github_org            = var.github_org
  admins                = var.org_admins
  members               = var.org_members
  blocked_users         = var.org_blocked_users
  all_members_team_name = "all-members"
  is_organization       = false  # Disabled to avoid permission issues
  org_owner             = "thekloudwiz"
}

# GitHub Teams - Create and manage teams
module "teams" {
  source = "./modules/teams"

  for_each = var.github_teams

  name        = each.key
  description = each.value.description
  privacy     = each.value.privacy
  members     = each.value.members
  maintainers = each.value.maintainers

  admin_repositories    = each.value.admin_repositories
  maintain_repositories = each.value.maintain_repositories
  push_repositories     = each.value.push_repositories
  triage_repositories   = each.value.triage_repositories
  pull_repositories     = each.value.pull_repositories
  module_depends_on = [module.repositories]
}

# OIDC Provider - Single provider for GitHub Actions
module "oidc_provider" {
  source = "./modules/oidc-provider"

  project         = var.project_name
  thumbprint_list = var.thumbprint_list
  tags            = local.common_tags
}

# Custom Policies
module "permissions" {
  source = "./modules/permissions"

  project_name  = var.project_name
  template_vars = local.template_vars

  depends_on = [module.oidc_provider]
}

# IAM Roles
module "roles" {
  source = "./modules/roles"

  project_name      = var.project_name
  environment       = var.environment
  oidc_provider_arn = module.oidc_provider.arn
  github_org        = var.github_org
  policy_arns       = module.permissions.policy_arns
  repositories      = var.repositories

  depends_on = [module.permissions]
}

# GitHub Repositories - Managed separately for easier targeting
module "repositories" {
  source = "./modules/repositories"

  project_name = var.project_name
  repositories = var.repositories
}

# Trust Policies
module "trust_policies" {
  source = "./modules/trust-policies"

  role_arns             = module.roles.role_arns
  oidc_provider_arn     = module.oidc_provider.arn
  github_org            = var.github_org
  repositories          = var.repositories
  external_repositories = var.external_repositories
  environment           = var.environment

  depends_on = [module.roles]
}