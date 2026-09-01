data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# Numeric organization ID, for the immutable OIDC subject claim in
# modules/roles. Looked up rather than hardcoded so the value cannot drift.
data "github_organization" "this" {
  name = var.github_org
}
