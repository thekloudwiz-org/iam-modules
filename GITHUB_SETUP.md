# GitHub Actions Setup Guide

This document explains how to set up GitHub Actions for automated Terraform deployments.

## Required Repository Secrets

Configure the following secrets in your GitHub repository settings:

### 1. AWS_ROLE_ARN
The ARN of the IAM role that GitHub Actions will assume for AWS operations.

```
AWS_ROLE_ARN: arn:aws:iam::ACCOUNT-ID:role/GitHubActionsRole
```

### 2. GITHUB_TOKEN
GitHub Personal Access Token with repository management permissions.

```
GITHUB_TOKEN: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Required permissions:**
- `repo` (Full control of private repositories)
- `admin:org` (Full control of orgs and teams, read and write org projects)
- `delete_repo` (Delete repositories)

## Environment Protection Rules

Set up environment protection rules for each environment:

1. Go to **Settings** → **Environments**
2. Create environments: `dev`, `stg`, `qa`, `prd`
3. Configure protection rules:
   - **Required reviewers**: Add team members for production environments
   - **Wait timer**: Add delays for production deployments
   - **Deployment branches**: Restrict to `main` branch for production

## Workflow Triggers

### Terraform Plan (Pull Requests)
- Triggers on PRs to `main` or `develop` branches
- Runs `terraform plan` for affected environments
- Posts plan output as PR comments
- Validates Terraform configuration

### Terraform Apply (Main Branch)
- Triggers on pushes to `main` branch
- Automatically detects changed environments
- Deploys changes sequentially
- Creates issues on deployment failures

### Manual Deployment
- Use **Actions** → **Terraform Apply** → **Run workflow**
- Select environment and action (apply/destroy)
- Useful for hotfixes or rollbacks

### Drift Detection
- Runs daily at 6 AM UTC
- Checks all environments for configuration drift
- Creates GitHub issues when drift is detected
- Updates existing issues with new detections

### Repository Management
- Manual workflow for repository operations
- Actions: create-repositories, update-trust-policies, add-external-repo
- Useful for managing GitHub repositories and IAM trust policies

## Backend State Management

Each environment uses a separate state file in S3:

```
Bucket: thekloudwiz-tf-state-bucket
Keys:
  - iam-modules/dev-terraform.state
  - iam-modules/stg-terraform.state
  - iam-modules/qa-terraform.state
  - iam-modules/prd-terraform.state
```

## Local Development

For local development, initialize with environment-specific backend:

```bash
# Initialize for dev environment
make init dev

# Plan changes for dev
make plan dev

# Apply changes for dev
make apply dev
```

## Troubleshooting

### State Lock Issues
If you encounter state lock issues:

```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

### Backend Migration
To migrate from local to remote state:

```bash
# Initialize with new backend
terraform init -backend-config=backend/dev.hcl

# Terraform will prompt to migrate existing state
# Answer 'yes' to copy state to new backend
```

### Workflow Failures
Check the following if workflows fail:

1. **AWS Role Permissions**: Ensure the GitHub Actions role has necessary IAM permissions
2. **GitHub Token**: Verify token has required permissions and hasn't expired
3. **Backend Access**: Confirm S3 bucket exists and is accessible
4. **DynamoDB Table**: Ensure state locking table exists (terraform-state-lock)

## Security Best Practices

1. **Least Privilege**: IAM roles should have minimal required permissions
2. **Environment Isolation**: Use separate AWS accounts for different environments
3. **Secret Rotation**: Regularly rotate GitHub tokens and AWS credentials
4. **Branch Protection**: Enable branch protection rules on main branch
5. **Review Requirements**: Require code reviews for all changes
6. **Audit Logging**: Enable CloudTrail for AWS API calls
7. **State Encryption**: S3 backend uses encryption at rest and in transit
