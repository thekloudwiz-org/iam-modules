# GitHub Actions IAM Role for environment-specific deployments
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions-role"

  # Initial assume role policy with deny effect
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

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

  # Initial assume role policy with deny effect
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
      }
    ]
  })

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