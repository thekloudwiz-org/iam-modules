project_name = "thekloudwiz"
environment  = "prd"
# repository_name = "tf-iam-modules"

# # S3 backend configuration
bucket       = "thekloudwiz-terraform-state"
key          = "iam-modules/prd/terraform.tfstate"
region       = "eu-central"
encrypt      = true
use_lockfile = true