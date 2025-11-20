output "policy_arns" {
  description = "ARNs of the created IAM policies"
  value = merge(
    {
      for k, v in aws_iam_policy.deployment_permissions : k => v.arn
    },
    {
      pull_request_read_only = aws_iam_policy.pull_request_read_only.arn
    }
  )
}