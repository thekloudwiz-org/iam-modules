project_name = "thekloudwiz"
environment  = "qa"
# repository_name = "tf-iam-modules"

# S3 backend configuration
bucket       = "thekloudwiz-terraform-state"
key          = "iam-modules/qa/terraform.tfstate"
region       = "eu-central"
encrypt      = true
use_lockfile = true