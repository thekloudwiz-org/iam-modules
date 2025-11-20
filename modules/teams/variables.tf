variable "module_enabled" {
  description = "Whether to create resources within the module or not"
  type        = bool
  default     = true
}

variable "module_depends_on" {
  description = "A list of explicit dependencies for the module"
  type        = any
  default     = []
}

variable "name" {
  description = "The name of the team"
  type        = string
}

variable "description" {
  description = "A description of the team"
  type        = string
  default     = ""
}

variable "privacy" {
  description = "The level of privacy for the team. Must be one of 'secret' or 'closed'"
  type        = string
  default     = "closed"

  validation {
    condition     = contains(["secret", "closed"], var.privacy)
    error_message = "Privacy must be one of 'secret' or 'closed'."
  }
}

variable "parent_team_id" {
  description = "The ID of the parent team, if this is a nested team"
  type        = string
  default     = null
}

variable "ldap_dn" {
  description = "The LDAP Distinguished Name of the group where membership will be synchronized"
  type        = string
  default     = null
}

variable "create_default_maintainer" {
  description = "Whether to create a default maintainer for the team"
  type        = bool
  default     = false
}

variable "members" {
  description = "A list of GitHub usernames to add as members to the team"
  type        = list(string)
  default     = []
}

variable "maintainers" {
  description = "A list of GitHub usernames to add as maintainers to the team"
  type        = list(string)
  default     = []
}

variable "admin_repositories" {
  description = "A list of repository names that the team will have admin access to"
  type        = list(string)
  default     = []
}

variable "maintain_repositories" {
  description = "A list of repository names that the team will have maintain access to"
  type        = list(string)
  default     = []
}

variable "push_repositories" {
  description = "A list of repository names that the team will have push access to"
  type        = list(string)
  default     = []
}

variable "triage_repositories" {
  description = "A list of repository names that the team will have triage access to"
  type        = list(string)
  default     = []
}

variable "pull_repositories" {
  description = "A list of repository names that the team will have pull access to"
  type        = list(string)
  default     = []
}