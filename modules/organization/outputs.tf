output "org_id" {
  description = "ID of the GitHub organization"
  value       = length(data.github_organization.org) > 0 ? data.github_organization.org[0].id : null
}

output "org_name" {
  description = "Name of the GitHub organization"
  value       = length(data.github_organization.org) > 0 ? data.github_organization.org[0].name : var.github_org
}

output "all_team_id" {
  description = "ID of the team containing all members"
  value       = var.all_members_team_name != null && length(github_team.all) > 0 ? github_team.all[0].id : null
}

output "members" {
  description = "Map of organization members and their roles"
  value       = local.memberships
}