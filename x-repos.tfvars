external_repositories = {
  "terraform-aws-devsecops-soc2" = {
    description         = "Test repository with multiple environments"
    has_dev_environment = true
    environments        = ["dev", "stg", "qa", "prd"]
    topics              = ["development", "terraform", "testing"]
    visibility          = "public"
  }
}