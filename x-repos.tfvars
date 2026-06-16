external_repositories = {
  "terraform-aws-devsecops-soc2" = {
    description         = "Test repository with multiple environments"
    has_dev_environment = true
    environments        = ["dev", "stg", "qa", "prd"]
    topics              = ["development", "terraform", "testing"]
    visibility          = "public"
  }
  # jbcl — existing private repo (created outside this module). Included here as
  # an EXTERNAL repo so the shared GitHub Actions role trusts it
  # (repo:thekloudwiz-org/jbcl:environment:dev / :ref:refs/heads/dev /
  # :pull_request) WITHOUT this module creating the repo or applying branch
  # protection (branch protection is private-repo/paid-only and only applies to
  # managed `repositories`, never to `external_repositories`).
  "jbcl" = {
    description         = "JBCL — Film • Editorial • Media. Premium creative agency site (Next.js static export deployed to S3/CloudFront)."
    has_dev_environment = true
    environments        = ["dev"]
    topics              = ["nextjs", "static-site", "s3", "cloudfront", "website"]
    visibility          = "private"
  }
}