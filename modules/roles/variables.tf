variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, stg, prd)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  type        = string
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_org_id" {
  description = <<-DESC
    Numeric GitHub organization ID, used in the immutable OIDC subject claim.
    Pinned rather than wildcarded so that an organization deleted and
    re-registered under the same name cannot assume these roles.
  DESC
  type        = string
}

variable "policy_arns" {
  description = "Map of policy ARNs to attach to the role"
  type        = map(string)
}

variable "repositories" {
  description = "Map of repositories to create trust policies for"
  type        = map(any)
  default     = {}
}

variable "external_repositories" {
  description = "Map of external repositories to include in the OIDC trust policy"
  type        = map(any)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}