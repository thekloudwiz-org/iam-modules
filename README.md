# IAM Modules for DevSecOps

A comprehensive Terraform infrastructure for managing AWS IAM resources with automated GitHub Actions CI/CD pipeline, supporting multi-environment deployments with remote state management.

> **📖 Documentation:** This README covers architecture and quick start. For operations and troubleshooting, see [OPERATIONS.md](OPERATIONS.md). For GitHub Actions setup, see [GITHUB_SETUP.md](GITHUB_SETUP.md).

## 🏗️ Architecture Overview

This repository provides a complete DevSecOps solution for IAM management with:
- **Multi-environment support** (dev, stg, qa, prd)
- **Automated CI/CD** with GitHub Actions
- **Remote state management** with S3 backend
- **Drift detection** and monitoring
- **Security-first approach** with OIDC and least privilege

## 📁 Repository Structure

```
iam-modules/
├── .github/workflows/          # GitHub Actions CI/CD workflows
│   ├── terraform-plan.yml      # PR validation and planning
│   ├── terraform-apply.yml     # Automated deployments
│   ├── terraform-drift.yml     # Daily drift detection
│   └── repository-management.yml # Repository operations
├── backend/                    # S3 backend configurations
│   ├── dev.hcl                # Development environment
│   ├── stg.hcl                # Staging environment
│   ├── qa.hcl                 # QA environment
│   └── prd.hcl                # Production environment
├── environments/               # Environment-specific variables
│   ├── dev.tfvars             # Development settings
│   ├── stg.tfvars             # Staging settings
│   ├── qa.tfvars              # QA settings
│   └── prd.tfvars             # Production settings
├── modules/                    # Terraform modules
│   ├── oidc-provider/         # GitHub OIDC provider
│   ├── policies/              # IAM policies
│   ├── roles/                 # IAM roles
│   ├── repositories/          # GitHub repository management
│   └── trust-policies/        # Trust relationships
├── policies/                   # JSON policy documents
├── scripts/                    # Utility scripts
│   └── migrate-state.sh       # State migration helper
├── main.tf                     # Main Terraform configuration
├── variables.tf                # Input variables
├── provider.tf                 # Provider configurations
├── outputs.tf                  # Output values
├── locals.tf                   # Local values and tags
├── data.tf                     # Data sources
├── terraform.tfvars            # Common variables
├── global.tfvars              # Global settings
├── Makefile                    # Development commands
├── GITHUB_SETUP.md            # GitHub Actions setup guide
└── README.md                   # This file
```

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.5.0
- GitHub Personal Access Token
- S3 bucket for state storage (see Bootstrap section)

### Bootstrap Backend Infrastructure

**First-time setup only:**

1. **Create backend infrastructure**:
   ```bash
   cd bootstrap
   terraform init
   terraform apply
   ```

   This creates:
   - S3 bucket: `thekloudwiz-tf-state-bucket`
   - Versioning enabled for state history
   - Encryption enabled (AES256)
   - Public access blocked

2. **Verify backend**:
   ```bash
   aws s3 ls s3://thekloudwiz-tf-state-bucket --region eu-central-1
   ```

### Local Development Setup

1. **Clone and initialize**:
   ```bash
   git clone <repository-url>
   cd iam-modules
   
   # Initialize with remote state for dev environment
   terraform init -backend-config=backend/dev.hcl
   ```

2. **Set environment variables**:
   ```bash
   export TF_VAR_github_token="your-github-token"
   export AWS_PROFILE="your-aws-profile"  # Optional
   ```

3. **Validate configuration**:
   ```bash
   ./scripts/validate-config.sh
   ```

4. **Plan and apply changes**:
   ```bash
   # Plan changes for development
   terraform plan -var-file=environments/dev.tfvars -var-file=global.tfvars
   
   # Apply changes
   terraform apply -var-file=environments/dev.tfvars -var-file=global.tfvars
   ```

### GitHub Actions Setup

1. **Configure repository secrets**:
   - `AWS_ROLE_ARN`: IAM role for GitHub Actions
   - `GITHUB_TOKEN`: Personal access token with repo permissions

2. **Enable workflows**:
   - Push changes to trigger automated deployment
   - Create PRs to see Terraform plans
   - Use manual workflows for specific operations

See [GITHUB_SETUP.md](GITHUB_SETUP.md) for detailed setup instructions.

## 🔄 CI/CD Workflows

### Automated Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **Terraform Plan** | Pull Requests | Validates changes and shows plan output |
| **Terraform Apply** | Push to main | Automatically deploys approved changes |
| **Drift Detection** | Daily schedule | Monitors for configuration drift |
| **Repository Management** | Manual | Manages GitHub repositories and policies |

### Deployment Process

1. **Development**: Create feature branch and make changes
2. **Validation**: Open PR → Automated plan runs → Review plan output
3. **Deployment**: Merge PR → Automatic deployment to affected environments
4. **Monitoring**: Daily drift detection ensures consistency

## 🏢 Environment Management

### Remote State Configuration

Each environment maintains separate state files in S3:

```
Bucket: thekloudwiz-tf-state-bucket (eu-central-1)
├── iam-modules/dev-terraform.state
├── iam-modules/stg-terraform.state  
├── iam-modules/qa-terraform.state
└── iam-modules/prd-terraform.state
```

**State Management Features:**
- ✅ S3 versioning for state history
- ✅ Server-side encryption (AES256)
- ✅ Strong read-after-write consistency
- ✅ Automatic version cleanup (90 days)
- ✅ Public access blocked

### Environment-Specific Deployments

```bash
# Local development commands
make init dev     # Initialize dev environment
make plan stg     # Plan staging changes
make apply prd    # Apply production changes

# GitHub Actions (manual)
Actions → Terraform Apply → Select environment → Run workflow
```

## 📦 Module Overview

| Module | Purpose | Resources |
|--------|---------|-----------|
| **oidc-provider** | GitHub OIDC authentication | `aws_iam_openid_connect_provider` |
| **policies** | IAM permission policies | `aws_iam_policy` |
| **roles** | IAM roles for GitHub Actions | `aws_iam_role` |
| **repositories** | GitHub repository management | `github_repository` |
| **trust-policies** | Trust relationships | `aws_iam_role_policy_attachment` |

## 🔧 Repository Management

### Adding New Repositories

1. **Define in terraform.tfvars**:
   ```hcl
   repositories = {
     "my-new-repo" = {
       description         = "New application repository"
       has_dev_environment = true
       environments        = ["dev", "stg", "prd"]
       topics              = ["application", "terraform"]
       visibility          = "private"
     }
   }
   ```

2. **Deploy via PR**:
   - Create pull request with changes
   - Review Terraform plan
   - Merge to automatically create repository and update IAM policies

### Managing External Repositories

For repositories created outside Terraform:

```bash
# Via GitHub Actions
Actions → Repository Management → add-external-repo → Enter repo name

# Via local command
make update-external-repo dev my-external-repo
```

## 🔍 Monitoring & Operations

### Drift Detection
- **Automated**: Runs daily at 6 AM UTC
- **Manual**: Trigger via GitHub Actions
- **Alerts**: Creates GitHub issues when drift detected
- **Resolution**: Provides guidance for fixing drift

### Troubleshooting

| Issue | Solution |
|-------|----------|
| State lock | `terraform force-unlock LOCK_ID` |
| Backend migration | `./scripts/migrate-state.sh <env>` |
| Workflow failures | Check AWS permissions and GitHub token |
| Drift issues | Review GitHub issues for guidance |

### Available Make Commands

```bash
# Environment management
make init <env>           # Initialize with remote state
make plan <env>           # Plan environment changes
make apply <env>          # Apply environment changes
make destroy <env>        # Destroy environment resources

# Specific operations
make create-repo <env>    # Create repositories only
make update-tp <env>      # Update trust policies only
make validate             # Validate Terraform configuration
make help                 # Show all available commands
```

## 🔒 Security Features

### Infrastructure Security
- **Encrypted S3 backend** with state locking
- **OIDC authentication** for GitHub Actions
- **Least privilege IAM policies**
- **Environment isolation** with separate state files
- **Branch protection** and required reviews

### Operational Security
- **Automated drift detection**
- **Deployment failure notifications**
- **Audit logging** via CloudTrail
- **Secret management** via GitHub repository secrets
- **Multi-environment approval workflows**

## 📚 Documentation

### Core Documentation
- **[README.md](README.md)** (this file) - Main documentation and quick start
- **[GITHUB_SETUP.md](GITHUB_SETUP.md)** - GitHub Actions CI/CD setup guide
- **[OPERATIONS.md](OPERATIONS.md)** - Operations, troubleshooting, and disaster recovery

### Additional Resources
- **[bootstrap/README.md](bootstrap/README.md)** - Backend infrastructure setup
- **[Makefile](Makefile)** - All available development commands

### Utility Scripts
- `scripts/setup-github-token.sh` - Setup GitHub token permanently
- `scripts/migrate-state.sh` - Migrate from local to remote state
- `scripts/backup-state.sh` - Backup state from S3
- `scripts/restore-state.sh` - Restore state from backup
- `scripts/validate-config.sh` - Validate configuration before apply

## 🚀 Quick Reference

### Common Commands

```bash
# Setup (one time)
make setup-token              # Setup GitHub token
make init dev                 # Initialize dev environment

# Daily operations
make plan-dev                 # Plan dev changes
make apply-dev                # Apply dev changes
make backup dev               # Backup dev state

# Validation
make validate                 # Basic validation
make validate-all             # Comprehensive checks
make fmt                      # Format code

# Help
make help                     # Show all commands
```

### CI/CD Workflows

```bash
# Deploy to dev
git checkout dev
git push origin dev           # Auto-deploys to dev

# Deploy to production
# 1. Create PR to main
# 2. Review plan in PR comments
# 3. Merge PR → Auto-deploys to prd
```

### Emergency Commands

```bash
# Restore corrupted state
./scripts/restore-state.sh backups/terraform.tfstate.backup

# Check current backend
cat .terraform/terraform.tfstate | jq '.backend.config.key'

# List state versions
aws s3api list-object-versions \
  --bucket thekloudwiz-tf-state-bucket \
  --prefix iam-modules/dev-terraform.state \
  --region eu-central-1
```

## 🤝 Contributing

1. Create feature branch from `main`
2. Make changes and test locally
3. Create pull request with clear description
4. Review Terraform plan output in PR comments
5. Merge after approval to trigger deployment

## 📞 Support

For issues and questions:
- **Troubleshooting:** See [OPERATIONS.md](OPERATIONS.md#troubleshooting)
- **GitHub Actions:** See [GITHUB_SETUP.md](GITHUB_SETUP.md)
- **Disaster Recovery:** See [OPERATIONS.md](OPERATIONS.md#disaster-recovery)
- **Create GitHub issue** for bugs or feature requests
- **Check workflow logs** in Actions tab