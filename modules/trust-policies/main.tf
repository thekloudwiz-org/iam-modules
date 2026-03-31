locals {
  # Map of environment to allowed branches
  env_branch_mapping = {
    dev = ["dev"]
    stg = ["main"]
    qa  = ["main"]
    prd = ["main"]
  }

  # Map of environment to allowed environments
  allowed_environments = {
    dev = ["dev"]
    stg = ["stg"]
    qa  = ["qa"]
    prd = ["stg", "qa", "prd"]
  }

  # Extract role names from ARNs
  role_names = {
    for k, v in var.role_arns : k => element(split("/", v), length(split("/", v)) - 1)
  }

  # Combine managed and external repositories
  all_repositories = merge(var.repositories, var.external_repositories)

  # Generate repository sub patterns for each repository and environment
  repo_patterns = {
    for role_key, role_arn in var.role_arns : role_key => flatten([
      # Use the environment variable directly instead of parsing from role name
      local.env_branch_mapping[var.environment] != null ? [
        for repo_name, repo in local.all_repositories : [
          for branch in local.env_branch_mapping[var.environment] :
          "repo:${var.github_org}/${repo_name}:ref:refs/heads/${branch}"
        ]
      ] : []
    ])
  }

  # Generate environment patterns for each repository and environment
  env_patterns = {
    for role_key, role_arn in var.role_arns : role_key => flatten([

      local.allowed_environments[var.environment] != null ? [
        for repo_name, repo in local.all_repositories : [
          for env in local.allowed_environments[var.environment] :
          "repo:${var.github_org}/${repo_name}:environment:${env}"
        ]
      ] : []
    ])
  }

  # Combine patterns for each role
  combined_patterns = {
    for role_key, role_arn in var.role_arns : role_key => concat(
      local.repo_patterns[role_key],
      local.env_patterns[role_key]
    )
  }
}

# Generate trust policy JSON files
# Generate trust policy JSON files
resource "local_file" "trust_policy" {
  for_each = local.role_names

  filename = "${path.module}/trust-policy-${each.value}.json"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = concat(
              local.combined_patterns[each.key],
              # Add pull request pattern for all repositories
              [for repo_name, repo in local.all_repositories :
                "repo:${var.github_org}/${repo_name}:pull_request"
              ]
            )
          }
        }
      }
    ]
  })

  # Format the JSON file after creation
  # provisioner "local-exec" {
  #   command     = "jq . ${self.filename} > ${self.filename}.tmp && mv ${self.filename}.tmp ${self.filename}"
  #   interpreter = ["PowerShell", "-Command"]
  # }
}


# Update the assume role policy using null_resource
resource "null_resource" "update_trust_policy" {
  for_each = local.role_names

  triggers = {
    policy_file = local_file.trust_policy[each.key].filename
    role_name   = each.value
    timestamp   = timestamp() # This ensures it runs on every apply
  }

  provisioner "local-exec" {
    command = "aws iam update-assume-role-policy --role-name ${each.value} --policy-document file://${local_file.trust_policy[each.key].filename}"
  }

  depends_on = [local_file.trust_policy]
}