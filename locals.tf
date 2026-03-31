locals {
  common_tags = {
    Project   = var.project_name
    Purpose   = "streamline iam with terraform"
    ManagedBy = "terraform"
  }

  # Template variables for policies
  template_vars = {
    project     = var.project_name
    environment = var.environment
    account_id  = data.aws_caller_identity.current.account_id
    region      = data.aws_region.current.id
    partition   = data.aws_partition.current.partition
  }
}