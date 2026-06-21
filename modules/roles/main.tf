# OIDC trust policy, computed in-line and set directly on each role's
# assume_role_policy. This replaces the previous trust-policies module, which
# created the role with a Deny stub and then pushed the real policy out-of-band
# via a null_resource `aws iam update-assume-role-policy` keyed on timestamp() —
# forcing a destroy/recreate on every apply and momentarily leaving the role on
# Deny mid-apply. The policy is pure data (no CLI behaviour the resource can't
# express), so this yields the identical effective trust while planning clean.
locals {
  # GitHub ref branch allowed to assume the role, per environment.
  env_branch_mapping = {
    dev = ["dev"]
    stg = ["main"]
    qa  = ["main"]
    prd = ["main"]
  }
  # GitHub Actions environments allowed to assume the role, per environment.
  allowed_environments = {
    dev = ["dev"]
    stg = ["stg"]
    qa  = ["qa"]
    prd = ["stg", "qa", "prd"]
  }

  # Managed + external repos, iterated by key (sorted) so the sub list is
  # deterministic — matches what the old module produced, byte for byte.
  trust_repositories = merge(var.repositories, var.external_repositories)

  # Order preserved from the old module: branch refs, then environments, then
  # pull_request — so the migrating apply is a no-op on the policy itself.
  oidc_sub_patterns = concat(
    flatten([
      for repo_name, repo in local.trust_repositories : [
        for branch in local.env_branch_mapping[var.environment] :
        "repo:${var.github_org}/${repo_name}:ref:refs/heads/${branch}"
      ]
    ]),
    flatten([
      for repo_name, repo in local.trust_repositories : [
        for env in local.allowed_environments[var.environment] :
        "repo:${var.github_org}/${repo_name}:environment:${env}"
      ]
    ]),
    [
      for repo_name, repo in local.trust_repositories :
      "repo:${var.github_org}/${repo_name}:pull_request"
    ]
  )

  oidc_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = var.oidc_provider_arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.oidc_sub_patterns
          }
        }
      }
    ]
  })
}

# GitHub Actions IAM Role for environment-specific deployments
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions-role"

  assume_role_policy = local.oidc_assume_role_policy

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-github-actions-role"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# For production environments, use the split deployment policies
resource "aws_iam_role_policy_attachment" "deployment_policies" {
  for_each = var.environment == "prd" ? toset(["deployment_part1", "deployment_part2", "deployment_part3", "deployment_part4", "deployment_part5"]) : []

  role       = aws_iam_role.github_actions.name
  policy_arn = var.policy_arns[each.value]
}

# For development environments, use the wildcard policy
resource "aws_iam_role_policy_attachment" "wildcard_policy" {
  count = var.environment != "prd" ? 1 : 0

  role       = aws_iam_role.github_actions.name
  policy_arn = var.policy_arns["wildcard"]
}

# GitHub Actions IAM Role for pull requests (read-only)
resource "aws_iam_role" "pull_request" {
  name = "${var.project_name}-${var.environment}-pull-request-role"

  # Same OIDC trust as the deploy role (parity with the prior module, which
  # computed an identical sub list for both roles). Access is differentiated
  # by the attached permission policies, not the trust policy.
  assume_role_policy = local.oidc_assume_role_policy

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-pull-request-role"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# Attach read-only policy to pull request role
resource "aws_iam_role_policy_attachment" "pull_request_policy" {
  role       = aws_iam_role.pull_request.name
  policy_arn = var.policy_arns["readonly"]
}