external_repositories = {
  "terraform-aws-devsecops-soc2" = {
    description         = "Test repository with multiple environments"
    has_dev_environment = true
    environments        = ["dev", "stg", "qa", "prd"]
    topics              = ["development", "terraform", "testing"]
    visibility          = "public"
  },
  "iam-modules" = {
    description         = "Centralized IAM, OIDC, and GitHub organization management with Terraform."
    has_dev_environment = true
    environments        = ["dev", "stg", "qa", "prd"]
    topics              = ["iam", "terraform", "oidc", "github-actions", "ci-cd"]
    visibility          = "public"
  },
  "jbcl" = {
    description         = "JBCL — Film • Editorial • Media. Premium creative agency site (Next.js static export deployed to S3/CloudFront)."
    has_dev_environment = true
    environments        = ["dev"]
    topics              = ["nextjs", "static-site", "s3", "cloudfront", "website"]
    visibility          = "private"
  }
}