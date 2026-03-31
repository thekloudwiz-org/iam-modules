variable "region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for state storage"
  type        = string
  default     = "thekloudwiz-tf-state-bucket"
}

variable "enable_object_lock" {
  description = "Enable S3 Object Lock for additional state protection"
  type        = bool
  default     = false
}
