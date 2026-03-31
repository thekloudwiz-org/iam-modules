output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_region" {
  description = "Region of the S3 bucket"
  value       = var.region
}

output "backend_config" {
  description = "Backend configuration for use in other Terraform projects"
  value = {
    bucket  = aws_s3_bucket.terraform_state.id
    region  = var.region
    encrypt = true
  }
}

output "backend_config_hcl" {
  description = "Backend configuration in HCL format"
  value       = <<-EOT
    bucket  = "${aws_s3_bucket.terraform_state.id}"
    region  = "${var.region}"
    encrypt = true
  EOT
}
