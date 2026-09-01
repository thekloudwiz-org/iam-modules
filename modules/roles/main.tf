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

  # GitHub emits the OIDC subject claim in two formats:
  #
  #   classic    repo:ORG/REPO:environment:dev
  #   immutable  repo:ORG@216174784/REPO@1353919829:environment:dev
  #
  # Repos created before immutable subject claims rolled out send the classic
  # form; every repo created since sends the immutable form. Neither the org-
  # nor the repo-level "use immutable subject claim" toggle turns this off for
  # new repos — verified against thekloudwiz-org, where the org setting is
  # unchecked and a new repo still emitted the immutable form. So both formats
  # have to be trusted, permanently.
  #
  # The REPO portion is wildcarded rather than enumerated per repository.
  # Enumerating both formats for every repo does not fit inside an IAM trust
  # policy: the prd role alone would need ~100 patterns, roughly 6300
  # characters against a hard limit of 2048 (4096 at maximum quota). The dev
  # role was already at 1929 of 2048 with one format and ten repos.
  #
  # The ORG portion is deliberately NOT wildcarded. Pinning the numeric org ID
  # preserves the property immutable subject claims exist for: an organization
  # deleted and re-registered under the same name gets a different ID and will
  # not match. A GitHub org name cannot contain "@", so neither prefix can be
  # spoofed by a lookalike organization.
  #
  # Trade-off worth knowing: trust is now scoped to "any repository in this
  # org" rather than an explicit allowlist. Every repo in the org was already
  # on that allowlist, so this is not a practical widening today — but adding a
  # repo to the org now grants it this role without a Terraform change.
  repo_prefixes = [
    "repo:${var.github_org}/*",
    "repo:${var.github_org}@${var.github_org_id}/*",
  ]

  # Sub-claim patterns, by source. The deploy role allows branch pushes +
  # GitHub environments + PRs; the read-only PR role allows PRs only, so a
  # pull_request workflow can never assume the deploy role's permissions.
  branch_subs = flatten([
    for prefix in local.repo_prefixes : [
      for branch in local.env_branch_mapping[var.environment] :
      "${prefix}:ref:refs/heads/${branch}"
    ]
  ])
  environment_subs = flatten([
    for prefix in local.repo_prefixes : [
      for env in local.allowed_environments[var.environment] :
      "${prefix}:environment:${env}"
    ]
  ])
  pull_request_subs = [
    for prefix in local.repo_prefixes : "${prefix}:pull_request"
  ]

  # Per-role sub lists. Deploy order preserved from the old module (branch,
  # environment, pull_request) so the migration is a no-op on that role.
  role_sub_patterns = {
    github_actions = concat(local.branch_subs, local.environment_subs, local.pull_request_subs)
    pull_request   = local.pull_request_subs
  }

  assume_role_policies = {
    for role_key, subs in local.role_sub_patterns : role_key => jsonencode({
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
              "token.actions.githubusercontent.com:sub" = subs
            }
          }
        }
      ]
    })
  }
}

# GitHub Actions IAM Role for environment-specific deployments
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions-role"

  assume_role_policy = local.assume_role_policies["github_actions"]

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

  # Read-only role: assumable from pull_request events ONLY — never from a
  # branch push or environment deploy. (The prior module gave both roles the
  # same trust; this scopes the PR role down to its actual job.)
  assume_role_policy = local.assume_role_policies["pull_request"]

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

# AWS-managed ReadOnlyAccess so PR `terraform plan` jobs can refresh resources
# across every service a product stack touches (lambda, apigw, cognito,
# cloudfront, sns, ssm, kms, ...). The custom `readonly` policy above only
# covers a handful of services — enough for this repo, not for akyeba/gyaale.
# Read-only: a PR can refresh state but can't mutate anything.
resource "aws_iam_role_policy_attachment" "pull_request_readonly_managed" {
  role       = aws_iam_role.pull_request.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}