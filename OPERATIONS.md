# Operations Guide

Complete guide for operating, troubleshooting, and recovering the IAM modules infrastructure.

## Table of Contents

- [Environment Separation](#environment-separation)
- [Daily Operations](#daily-operations)
- [Troubleshooting](#troubleshooting)
- [Disaster Recovery](#disaster-recovery)
- [Maintenance](#maintenance)

---

## Environment Separation

### How It Works

Each environment uses **completely separate state files** in S3. Deploying to one environment will NEVER affect another.

**State Files:**
```
s3://thekloudwiz-tf-state-bucket/
├── iam-modules/dev-terraform.state    ← Dev resources only
├── iam-modules/stg-terraform.state    ← Staging resources only
├── iam-modules/qa-terraform.state     ← QA resources only
└── iam-modules/prd-terraform.state    ← Production resources only
```

### Deploying to Different Environments

**Deploy to Dev:**
```bash
terraform init -backend-config=backend/dev.hcl -reconfigure
terraform plan -var-file=environments/dev.tfvars -var-file=global.tfvars
terraform apply -var-file=environments/dev.tfvars -var-file=global.tfvars
```

**Deploy to Production:**
```bash
terraform init -backend-config=backend/prd.hcl -reconfigure
terraform plan -var-file=environments/prd.tfvars -var-file=global.tfvars
terraform apply -var-file=environments/prd.tfvars -var-file=global.tfvars
```

**Important:** Always use `-reconfigure` when switching environments to ensure you're using the correct state file.

### Verification

**Check which backend you're using:**
```bash
cat .terraform/terraform.tfstate | jq '.backend.config.key'
```

**List resources in each environment:**
```bash
# Dev resources
terraform init -backend-config=backend/dev.hcl -reconfigure
terraform state list

# Prd resources  
terraform init -backend-config=backend/prd.hcl -reconfigure
terraform state list
```

---

## Daily Operations

### Backup State Files

**Before any major changes:**
```bash
./scripts/backup-state.sh dev
./scripts/backup-state.sh stg
./scripts/backup-state.sh qa
./scripts/backup-state.sh prd
```

Backups are stored in `backups/` directory with timestamps.

### Validate Configuration

**Before applying changes:**
```bash
./scripts/validate-config.sh
```

This checks:
- Terraform formatting
- Configuration validity
- Sensitive data detection
- JSON policy validation
- Backend configuration consistency

### Check for Drift

**Detect configuration drift:**
```bash
terraform plan -detailed-exitcode \
  -var-file=environments/dev.tfvars \
  -var-file=global.tfvars
```

Exit codes:
- `0` = No changes (no drift)
- `1` = Error
- `2` = Changes detected (drift found)

### Add New Repository

1. Edit `global.tfvars`:
```hcl
repositories = {
  "my-new-repo" = {
    description         = "My new repository"
    has_dev_environment = true
    environments        = ["dev", "stg", "prd"]
    topics              = ["terraform", "aws"]
    visibility          = "private"
  }
}
```

2. Apply changes:
```bash
terraform plan -var-file=environments/dev.tfvars -var-file=global.tfvars
terraform apply -var-file=environments/dev.tfvars -var-file=global.tfvars
```

### Migrate from Local to Remote State

**If you have local state files:**
```bash
# Backup first
cp terraform.tfstate backups/terraform.tfstate.pre-migration.backup

# Run migration
./scripts/migrate-state.sh dev

# Verify
terraform state list
```

---

## Troubleshooting

### Backend Issues

#### Error: Backend configuration changed

**Solution:**
```bash
terraform init -reconfigure -backend-config=backend/dev.hcl
```

#### Error: Failed to get existing workspaces (AccessDenied)

**Cause:** AWS credentials don't have S3 access.

**Solution:**
```bash
# Verify credentials
aws sts get-caller-identity

# Check bucket access
aws s3 ls s3://thekloudwiz-tf-state-bucket --region eu-central-1

# Verify IAM permissions include:
# - s3:ListBucket
# - s3:GetObject
# - s3:PutObject
```

#### Error: Region mismatch

**Solution:**
All backend HCL files should use `region = "eu-central-1"` to match the bucket location.

### State Issues

#### Error: State file not found

**Solution:**
```bash
# Check if state exists
aws s3 ls s3://thekloudwiz-tf-state-bucket/iam-modules/ --region eu-central-1

# Verify backend config key matches
grep "key" backend/dev.hcl

# If migrating from local
./scripts/migrate-state.sh dev
```

#### Error: State file corrupted

**Solution:**
```bash
# Restore from backup
./scripts/restore-state.sh backups/terraform.tfstate.YYYYMMDD_HHMMSS.backup

# Or restore from S3 version
aws s3api list-object-versions \
  --bucket thekloudwiz-tf-state-bucket \
  --prefix iam-modules/dev-terraform.state \
  --region eu-central-1

# Download specific version
aws s3api get-object \
  --bucket thekloudwiz-tf-state-bucket \
  --key iam-modules/dev-terraform.state \
  --version-id <VERSION_ID> \
  recovered-state.json

# Push recovered state
terraform state push recovered-state.json
```

### GitHub Actions Issues

#### Error: AWS credentials not configured

**Solution:**
1. Verify `AWS_ROLE_ARN` secret exists in Settings → Secrets
2. Check OIDC provider exists in AWS
3. Verify trust policy allows GitHub Actions
4. Check role permissions

#### Error: GitHub token invalid (401)

**Solution:**
1. Generate new token at https://github.com/settings/tokens
2. Required scopes: `repo`, `admin:org`, `delete_repo`
3. Update `GITHUB_TOKEN` secret
4. Verify token hasn't expired

### Resource Issues

#### Error: Resource already exists

**Solution:**
```bash
# Import existing resource
terraform import module.oidc_provider.aws_iam_openid_connect_provider.github <ARN>
```

#### Error: Insufficient permissions (AccessDenied)

**Solution:**
```bash
# Check current permissions
aws iam get-user
aws iam list-attached-user-policies --user-name <username>

# Required permissions:
# - IAM: Full access for role/policy management
# - S3: Read/Write for state bucket
```

### Common Mistakes

#### ❌ Forgetting to reconfigure backend

```bash
# Wrong - still using old backend
terraform init -backend-config=backend/prd.hcl
terraform apply -var-file=environments/prd.tfvars -var-file=global.tfvars
```

**Correct:**
```bash
terraform init -backend-config=backend/prd.hcl -reconfigure
terraform apply -var-file=environments/prd.tfvars -var-file=global.tfvars
```

#### ❌ Using wrong tfvars with wrong backend

```bash
# Wrong - prd backend with dev variables
terraform init -backend-config=backend/prd.hcl -reconfigure
terraform apply -var-file=environments/dev.tfvars -var-file=global.tfvars
```

**Correct:**
```bash
terraform init -backend-config=backend/prd.hcl -reconfigure
terraform apply -var-file=environments/prd.tfvars -var-file=global.tfvars
```

### Debug Mode

**Enable debug logging:**
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform plan
```

**Inspect state:**
```bash
# List all resources
terraform state list

# Show specific resource
terraform state show module.oidc_provider.aws_iam_openid_connect_provider.github

# Pull state for inspection
terraform state pull > state.json
```

---

## Disaster Recovery

### Scenario 1: Corrupted State File

**Symptoms:**
- Terraform commands fail with state parsing errors
- State shows unexpected changes
- Resources appear missing

**Recovery:**

1. **Stop all operations immediately**

2. **List available versions:**
```bash
aws s3api list-object-versions \
  --bucket thekloudwiz-tf-state-bucket \
  --prefix iam-modules/dev-terraform.state \
  --region eu-central-1
```

3. **Download previous version:**
```bash
aws s3api get-object \
  --bucket thekloudwiz-tf-state-bucket \
  --key iam-modules/dev-terraform.state \
  --version-id <VERSION_ID> \
  terraform.tfstate.recovered
```

4. **Restore state:**
```bash
terraform state push terraform.tfstate.recovered
```

5. **Verify:**
```bash
terraform plan
```

### Scenario 2: Accidentally Deleted State File

**Recovery:**

1. **Check S3 versioning:**
```bash
aws s3api list-object-versions \
  --bucket thekloudwiz-tf-state-bucket \
  --prefix iam-modules/ \
  --region eu-central-1
```

2. **Restore from backup:**
```bash
./scripts/restore-state.sh backups/terraform.tfstate.backup
```

3. **If no backup, rebuild state:**
```bash
# Import resources one by one
terraform import module.oidc_provider.aws_iam_openid_connect_provider.github <ARN>
terraform import module.roles.aws_iam_role.github_actions <ROLE_NAME>
```

### Scenario 3: S3 Bucket Deletion

**Recovery:**

1. **Recreate backend:**
```bash
cd bootstrap
terraform init
terraform apply
```

2. **Restore state from local backup:**
```bash
terraform init -backend-config=backend/dev.hcl
terraform state push backups/terraform.tfstate.YYYYMMDD_HHMMSS.backup
```

3. **Verify and reconcile:**
```bash
terraform plan
terraform apply
```

### Scenario 4: Accidental Repository Deletion

**Recovery:**

1. **Check GitHub trash** (repos kept for 90 days)
2. **Contact GitHub support** for restoration
3. **Or recreate from Terraform:**
```bash
# Remove from state
terraform state rm 'module.repositories.github_repository.repos["repo-name"]'

# Recreate
terraform apply -target='module.repositories.github_repository.repos["repo-name"]'
```

### Backup Schedule

**Automated:**
- Before every apply operation
- Retention: 90 days (via S3 versioning)

**Manual:**
- Before major changes: Always
- Before production deployments: Required
- Monthly: Full infrastructure backup

**Weekly verification:**
```bash
./scripts/backup-state.sh dev
./scripts/backup-state.sh stg
./scripts/backup-state.sh qa
./scripts/backup-state.sh prd
```

### Recovery Time Objectives (RTO)

| Scenario | RTO | RPO |
|----------|-----|-----|
| State file corruption | < 15 min | 0 min |
| Accidental resource deletion | < 30 min | 0 min |
| Complete infrastructure loss | < 2 hours | 0 min |
| S3 bucket deletion | < 4 hours | 0 min |

---

## Maintenance

### Regular Tasks

**Daily:**
- Review drift detection reports
- Check GitHub Actions workflow status

**Weekly:**
- Review and update dependencies
- Verify backups are working
- Check for security updates

**Monthly:**
- Security audit and compliance check
- Review IAM policies
- Update documentation

**Quarterly:**
- Disaster recovery drill
- Performance review
- Cost optimization review

**Annually:**
- Architecture review
- Security assessment
- Team training

### Updating Terraform Version

1. **Update `.terraform-version`:**
```bash
echo "1.6.0" > .terraform-version
```

2. **Update `provider.tf`:**
```hcl
terraform {
  required_version = ">= 1.6.0"
}
```

3. **Test in dev first:**
```bash
terraform init -upgrade
terraform plan
terraform apply
```

4. **Roll out to other environments**

### Rotating Secrets

**GitHub Token:**
1. Generate new token at https://github.com/settings/tokens
2. Update `GITHUB_TOKEN` secret in repository settings
3. Test with a plan operation

**AWS Credentials:**
1. Rotate AWS access keys
2. Update GitHub Actions secrets
3. Test workflows

### Cleaning Up Old Resources

**Remove old state versions:**
```bash
# List versions older than 90 days
aws s3api list-object-versions \
  --bucket thekloudwiz-tf-state-bucket \
  --prefix iam-modules/ \
  --region eu-central-1 \
  --query 'Versions[?LastModified<`2024-08-01`]'

# Lifecycle policy handles this automatically
```

**Remove unused resources:**
```bash
# List all resources
terraform state list

# Remove specific resource
terraform state rm 'module.repositories.github_repository.repos["old-repo"]'
```

### Performance Optimization

**Use targeted operations:**
```bash
terraform plan -target=module.repositories
terraform apply -target=module.repositories
```

**Increase parallelism:**
```bash
terraform apply -parallelism=20
```

**Skip refresh for faster plans:**
```bash
terraform plan -refresh=false
```

### Monitoring

**Check state file size:**
```bash
aws s3 ls s3://thekloudwiz-tf-state-bucket/iam-modules/ \
  --region eu-central-1 --human-readable
```

**Count resources:**
```bash
terraform state list | wc -l
```

**Check workflow status:**
```bash
# Via GitHub CLI
gh run list --workflow=terraform-plan.yml
gh run list --workflow=terraform-drift.yml
```

---

## Best Practices

### Before Making Changes

1. ✅ Backup state: `./scripts/backup-state.sh <env>`
2. ✅ Validate config: `./scripts/validate-config.sh`
3. ✅ Review plan carefully
4. ✅ Test in dev first
5. ✅ Have rollback plan ready

### During Changes

1. ✅ Monitor apply progress
2. ✅ Watch for errors
3. ✅ Verify resources created correctly
4. ✅ Check CloudTrail logs

### After Changes

1. ✅ Verify with `terraform plan` (should show no changes)
2. ✅ Test functionality
3. ✅ Update documentation
4. ✅ Notify team

### Security

1. ✅ Never commit secrets to git
2. ✅ Use pre-commit hooks
3. ✅ Rotate credentials regularly
4. ✅ Review IAM policies quarterly
5. ✅ Enable MFA for production

---

## Emergency Contacts

- **AWS Support:** [AWS Support Portal](https://console.aws.amazon.com/support/)
- **GitHub Support:** support@github.com
- **Team Lead:** See internal documentation
- **On-call Engineer:** See PagerDuty

## Useful Commands Reference

```bash
# State management
terraform state list                    # List all resources
terraform state show <resource>         # Show resource details
terraform state pull > state.json       # Download state
terraform state push state.json         # Upload state

# Backup and restore
./scripts/backup-state.sh <env>        # Backup state
./scripts/restore-state.sh <file>      # Restore state

# Validation
./scripts/validate-config.sh           # Validate configuration
terraform fmt -check -recursive        # Check formatting
terraform validate                     # Validate syntax

# Environment switching
terraform init -backend-config=backend/<env>.hcl -reconfigure

# Debugging
export TF_LOG=DEBUG                    # Enable debug logging
terraform plan -out=plan.tfplan        # Save plan
terraform show plan.tfplan             # View saved plan

# AWS verification
aws sts get-caller-identity            # Check AWS identity
aws s3 ls s3://bucket --region region  # Check bucket access
```

---

**Last Updated:** November 20, 2024  
**Version:** 1.0.0
