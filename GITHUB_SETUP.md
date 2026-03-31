# GitHub Actions Setup Guide

This document explains how to set up GitHub Actions for automated Terraform deployments using reusable workflows.

## CI/CD Workflow Overview

### Workflow Strategy

```
Branch Push (dev/stg/qa/prd)
  ↓
  Format → Validate → Plan → Apply to respective environment

Pull Request to main
  ↓
  Format → Validate → Plan (prd) → Comment on PR

Merge to main
  ↓
  Format → Validate → Plan → Apply to prd → Notify
```

### Workflows

1. **terraform-reusable.yml** - Core reusable workflow
2. **branch-deploy.yml** - Deploy on branch push
3. **pull-request.yml** - Plan on PR to main
4. **production-deploy.yml** - Deploy to production on merge
5. **terraform-drift.yml** - Daily drift detection
6. **repository-management.yml** - Manual repository operations

## Required Repository Secrets

Configure the following secrets in your GitHub repository settings:

### 1. AWS_ROLE_ARN
The ARN of the IAM role that GitHub Actions will assume for AWS operations.

```
AWS_ROLE_ARN: arn:aws:iam::ACCOUNT-ID:role/GitHubActionsRole
```

**Note:** This role will be created by this Terraform configuration.

### 2. GITHUB_TOKEN
GitHub Personal Access Token with repository management permissions.

```
GITHUB_TOKEN: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Required permissions:**
- `repo` (Full control of private repositories)
- `admin:org` (Full control of orgs and teams, read and write org projects)
- `delete_repo` (Delete repositories)

## Branch Strategy

### Environment Branches

Create and protect these branches:

- `dev` - Development environment
- `stg` - Staging environment
- `qa` - QA/Testing environment
- `prd` - Production environment (optional, or use main)
- `main` - Production deployment branch

### Branch Protection Rules

**For main branch:**
1. Go to **Settings** → **Branches** → **Add rule**
2. Branch name pattern: `main`
3. Enable:
   - ✅ Require pull request reviews before merging
   - ✅ Require status checks to pass (select "Plan Production Changes")
   - ✅ Require branches to be up to date
   - ✅ Include administrators

**For environment branches (dev, stg, qa, prd):**
1. Optional: Add protection rules
2. Consider requiring status checks
3. Allow direct pushes for faster iteration

## Workflow Triggers

### 1. Branch Deploy (branch-deploy.yml)
**Triggers:** Push to `dev`, `stg`, `qa`, or `prd` branches

**Actions:**
- Auto-formats Terraform files
- Validates configuration
- Plans changes
- **Applies changes automatically** to the respective environment

**Example:**
```bash
git checkout dev
git add .
git commit -m "feat: add new IAM policy"
git push origin dev
# → Automatically deploys to dev environment
```

### 2. Pull Request (pull-request.yml)
**Triggers:** PR to `main` branch

**Actions:**
- Auto-formats Terraform files
- Validates configuration
- Plans changes for **production**
- Posts plan as PR comment
- **Does NOT apply** (review only)

**Example:**
```bash
git checkout -b feature/new-policy
# Make changes
git push origin feature/new-policy
# Create PR to main
# → Shows production plan in PR comments
```

### 3. Production Deploy (production-deploy.yml)
**Triggers:** Merge to `main` branch

**Actions:**
- Auto-formats Terraform files
- Validates configuration
- Plans changes for production
- **Applies changes to production**
- Creates success notification issue

**Example:**
```bash
# After PR is approved and merged
# → Automatically deploys to production
# → Creates GitHub issue with deployment details
```

### 4. Drift Detection (terraform-drift.yml)
**Triggers:** Daily at 6 AM UTC, or manual

**Actions:**
- Checks all environments for drift
- Creates/updates GitHub issues
- Provides remediation guidance

### 5. Repository Management (repository-management.yml)
**Triggers:** Manual workflow dispatch

**Actions:**
- Create repositories
- Update trust policies
- Add external repositories

## Deployment Flow Examples

### Deploying to Development

```bash
# 1. Create feature branch from dev
git checkout dev
git pull origin dev
git checkout -b feature/add-new-policy

# 2. Make changes
# Edit files...

# 3. Commit and push to dev
git add .
git commit -m "feat: add new deployment policy"
git push origin dev

# 4. GitHub Actions automatically:
#    - Formats code
#    - Validates
#    - Plans
#    - Applies to dev environment
```

### Deploying to Production

```bash
# 1. Create PR from dev to main
git checkout dev
git pull origin dev
git push origin dev

# Create PR: dev → main

# 2. GitHub Actions automatically:
#    - Plans production changes
#    - Posts plan in PR comments

# 3. Review the plan in PR

# 4. Merge PR to main

# 5. GitHub Actions automatically:
#    - Applies to production
#    - Creates success notification
```

### Promoting Through Environments

```bash
# 1. Develop in dev branch
git checkout dev
# Make changes, test
git push origin dev
# → Deploys to dev

# 2. Promote to staging
git checkout stg
git merge dev
git push origin stg
# → Deploys to stg

# 3. Promote to QA
git checkout qa
git merge stg
git push origin qa
# → Deploys to qa

# 4. Promote to production
git checkout dev
# Create PR to main
# Review and merge
# → Deploys to prd
```

## Backend State Management

Each environment uses a separate state file in S3:

```
Bucket: thekloudwiz-tf-state-bucket (eu-central-1)
Keys:
  - iam-modules/dev-terraform.state
  - iam-modules/stg-terraform.state
  - iam-modules/qa-terraform.state
  - iam-modules/prd-terraform.state
```

## Local Development

For local development, initialize with environment-specific backend:

```bash
# Setup GitHub token (one time)
make setup-token

# Initialize for dev environment
make init dev

# Plan changes for dev
make plan-dev

# Apply changes for dev
make apply-dev
```

## Troubleshooting

For detailed troubleshooting, see [OPERATIONS.md](OPERATIONS.md#troubleshooting).

### Quick Fixes

**Workflow Failures:**
1. Check AWS Role Permissions
2. Verify GitHub Token hasn't expired
3. Confirm S3 bucket access
4. Review workflow logs in Actions tab

**State Issues:**
```bash
# Migrate from local to remote state
./scripts/migrate-state.sh dev

# Backup state before changes
./scripts/backup-state.sh dev
```

**For more help:**
- [OPERATIONS.md](OPERATIONS.md) - Complete troubleshooting guide
- [README.md](README.md) - Main documentation

## Security Best Practices

1. **Least Privilege**: IAM roles should have minimal required permissions
2. **Environment Isolation**: Use separate AWS accounts for different environments
3. **Secret Rotation**: Regularly rotate GitHub tokens and AWS credentials
4. **Branch Protection**: Enable branch protection rules on main branch
5. **Review Requirements**: Require code reviews for all changes
6. **Audit Logging**: Enable CloudTrail for AWS API calls
7. **State Encryption**: S3 backend uses encryption at rest and in transit
