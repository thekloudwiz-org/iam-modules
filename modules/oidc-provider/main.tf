resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = var.thumbprint_list

  tags = merge(
    var.tags,
    {
      Name      = "${var.project}-github-oidc"
      Project   = var.project
      ManagedBy = "terraform"
    }
  )
}