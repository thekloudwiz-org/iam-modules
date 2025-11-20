variable "project_name" {
  description = "Project name"
  type        = string
}

variable "template_vars" {
  description = "Variables to use in policy templates"
  type        = map(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}