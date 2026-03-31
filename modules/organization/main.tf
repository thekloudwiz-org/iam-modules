# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MANAGE A GITHUB ORGANIZATION
#   - manage memberships ( admins and members )
#   - manage blocked users
#   - manage projects
#   - create the team "all" that contains every member of the organization
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

locals {
  # Filter out the organization owner from admins and members
  filtered_admins  = { for i in var.admins : lower(i) => "admin" if lower(i) != lower(var.org_owner) }
  filtered_members = { for i in var.members : lower(i) => "member" if lower(i) != lower(var.org_owner) }
  memberships      = merge(local.filtered_admins, local.filtered_members)
}

# Safeguard for validating if a GitHub user exists on `terraform plan`
data "github_user" "user" {
  for_each = var.catch_non_existing_members ? local.memberships : {}

  username = each.key
}

resource "github_membership" "membership" {
  for_each = var.is_organization ? local.memberships : {}

  username = each.key
  role     = each.value
}

resource "github_organization_block" "blocked_user" {
  for_each = var.is_organization ? var.blocked_users : toset([])

  username = each.value
}

resource "github_team" "all" {
  count = var.all_members_team_name != null && var.is_organization ? 1 : 0

  name        = var.all_members_team_name
  description = "This team contains all members of our organization."
  privacy     = var.all_members_team_visibility
}

resource "github_team_membership" "all" {
  for_each = var.all_members_team_name != null && var.is_organization ? local.memberships : {}

  team_id  = length(github_team.all) > 0 ? github_team.all[0].id : ""
  username = each.key
  role     = "member"
}