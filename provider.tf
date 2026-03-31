terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    github = {
      source  = "integrations/github"
      version = "> 5.0.0"
    }
  }

  backend "s3" {
    # Backend configuration will be provided via -backend-config flag
    # See backend/*.hcl files for environment-specific configurations
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "github" {
  token        = var.github_token
  owner = var.github_org
}