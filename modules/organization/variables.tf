variable "github_org" {
  description = "Name of the GitHub organization"
  type        = string
}

variable "admins" {
  description = "List of GitHub usernames that should be admins of the organization (do not include the organization owner)"
  type        = list(string)
  default     = []
}

variable "members" {
  description = "List of GitHub usernames that should be members of the organization (do not include the organization owner)"
  type        = list(string)
  default     = []
}

variable "blocked_users" {
  description = "List of GitHub usernames that should be blocked from the organization"
  type        = set(string)
  default     = []
}

variable "catch_non_existing_members" {
  description = "Whether to validate if users exist before adding them to the organization"
  type        = bool
  default     = true
}

variable "all_members_team_name" {
  description = "Name of the team that should contain all members of the organization"
  type        = string
  default     = "all"
}

variable "all_members_team_visibility" {
  description = "Visibility of the all members team"
  type        = string
  default     = "closed"
}

variable "is_organization" {
  description = "Whether the GitHub account is an organization or a user"
  type        = bool
  default     = true
}

variable "org_owner" {
  description = "GitHub username of the organization owner (will be excluded from membership management)"
  type        = string
}