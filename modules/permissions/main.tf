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
      },
      # A PR `terraform plan` refreshes aws_secretsmanager_secret_version
      # resources, and the AWS-managed ReadOnlyAccess policy deliberately
      # withholds GetSecretValue. Any repo that manages secrets in terraform
      # therefore fails its plan outright and can never show a green gate —
      # gyaale did, 2026-09-04, on a PR that only touched CloudWatch alarms.
      #
      # Scoped to the product secret prefixes, never the account, and read
      # only: no put, no rotate, no delete. Add a prefix here when another
      # product starts managing secrets in terraform.
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          "arn:${var.template_vars.partition}:secretsmanager:${var.template_vars.region}:${var.template_vars.account_id}:secret:gyaale/*"
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