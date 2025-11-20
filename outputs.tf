output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = module.oidc_provider.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = module.oidc_provider.url
}

output "role_name" {
  description = "Name of the IAM role"
  value       = module.roles.role_name
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = module.roles.role_arn
}

output "policy_arns" {
  description = "ARNs of the created IAM policies"
  value       = module.permissions.policy_arns
}

# output "repository_urls" {
#   description = "URLs of the created repositories"
#   value       = module.repositories.repository_urls
# }