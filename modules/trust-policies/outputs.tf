output "updated_roles" {
  description = "List of roles that were updated"
  value       = [for k, v in local.role_names : v]
}

output "trust_policy_files" {
  description = "Trust policy files that were created"
  value = {
    for k, v in local.role_names : v => local_file.trust_policy[k].filename
  }
}

output "trust_policy_json" {
  description = "JSON content of the trust policies"
  value = {
    for k, v in local.role_names : v => local_file.trust_policy[k].content
  }
}