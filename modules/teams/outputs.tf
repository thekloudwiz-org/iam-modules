output "team_id" {
  description = "The ID of the created team"
  value       = try(github_team.team[0].id, null)
}

output "team_node_id" {
  description = "The node ID of the created team"
  value       = try(github_team.team[0].node_id, null)
}

output "team_slug" {
  description = "The slug of the created team"
  value       = try(github_team.team[0].slug, null)
}

output "team_members" {
  description = "Map of team members and their roles"
  value       = local.memberships
}

output "team_repositories" {
  description = "Map of repositories and their permission levels"
  value       = local.repositories
}