# Create IAM policies from JSON files
resource "aws_iam_policy" "deployment_permissions" {
  for_each = local.policies

  name        = each.value.name
  path        = each.value.path
  description = each.value.description

  # Use templatefile to substitute variables in policy JSON
  policy = templatefile(
    each.value.policy_file,
    var.template_vars
  )

  tags = merge(
    var.tags,
    {
      Name    = each.value.name
      Project = var.project_name
    }
  )
}

# Create read-only state policy for pull requests
resource "aws_iam_policy" "pull_request_read_only" {
  name        = "${var.project_name}-pull-request-read-only-policy"
  description = "Policy for read-only access to Terraform state for pull requests"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:${var.template_vars.partition}:s3:::${var.project_name}-terraform-state",
          "arn:${var.template_vars.partition}:s3:::${var.project_name}-terraform-state/*/*"
        ]
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-pull-request-read-only-policy"
      Project = var.project_name
    }
  )
}