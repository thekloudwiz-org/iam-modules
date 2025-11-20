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

variable "policy_arns" {
  description = "Map of policy ARNs to attach to the role"
  type        = map(string)
}

variable "repositories" {
  description = "Map of repositories to create trust policies for"
  type        = map(any)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}