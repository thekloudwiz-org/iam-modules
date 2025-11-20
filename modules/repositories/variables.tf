variable "project_name" {
  description = "Project name"
  type        = string
}

variable "repositories" {
  description = "Map of repositories to create"
  type = map(object({
    description              = string
    has_dev_environment      = bool
    environments             = list(string)
    topics                   = list(string)
    visibility               = string
    code_owners              = optional(list(string))
    require_code_owner_reviews = optional(bool, false)
  }))
  default = {} # Allow empty map for flexibility
}