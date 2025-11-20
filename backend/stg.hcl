bucket         = "thekloudwiz-tf-state-bucket"
key            = "iam-modules/stg-terraform.state"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock"
