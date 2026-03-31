variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stg, qa, prd)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "qa", "prd", "global"], var.environment)
    error_message = "Environment must be one of: dev, stg, qa, prd Or global."
  }
}

variable "owner" {
  description = "Name of the repository owner"
  type        = string
  default     = ""
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "org_admins" {
  description = "List of GitHub usernames that should be admins of the organization"
  type        = list(string)
  default     = []
}

variable "org_members" {
  description = "List of GitHub usernames that should be members of the organization"
  type        = list(string)
  default     = []
}

variable "org_blocked_users" {
  description = "List of GitHub usernames that should be blocked from the organization"
  type        = set(string)
  default     = []
}

variable "github_teams" {
  description = "Map of teams to create in the organization"
  type = map(object({
    description           = string
    privacy               = string
    members               = list(string)
    maintainers           = list(string)
    admin_repositories    = list(string)
    maintain_repositories = list(string)
    push_repositories     = list(string)
    triage_repositories   = list(string)
    pull_repositories     = list(string)
  }))
  default = {}
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "thumbprint_list" {
  description = "List of thumbprints for the OIDC provider"
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "repositories" {
  description = "Map of repositories to create"
  type = map(object({
    description         = string
    has_dev_environment = bool
    environments        = list(string)
    topics              = list(string)
    visibility          = string
    code_owners         = optional(list(string), [])
  }))
  default = {}
}

variable "external_repositories" {
  description = "Map of external repositories to include in trust policies"
  type = map(object({
    description         = string
    has_dev_environment = bool
    environments        = list(string)
    topics              = list(string)
    visibility          = string
  }))
  default = {}
}