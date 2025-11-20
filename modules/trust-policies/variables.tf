variable "role_arns" {
  description = "Map of role ARNs to update trust policies for"
  type        = map(string)
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  type        = string
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "repositories" {
  description = "Map of repositories to create trust policies for"
  type        = map(any)
  default     = {}
}

variable "external_repositories" {
  description = "Map of external repositories to include in trust policies"
  type        = map(any)
  default     = {}
}

variable "environment" {
  description = "Environment name"
  type        = string
}