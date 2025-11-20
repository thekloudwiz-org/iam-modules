output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.github_actions.name
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.github_actions.arn
}

output "role_arns" {
  description = "Map of role ARNs"
  value = {
    github_actions = aws_iam_role.github_actions.arn
    pull_request   = aws_iam_role.pull_request.arn
  }
}

output "pull_request_role_arn" {
  description = "ARN of the pull request role"
  value       = aws_iam_role.pull_request.arn
}