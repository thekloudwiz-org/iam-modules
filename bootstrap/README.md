# Terraform Backend Bootstrap

This directory contains the infrastructure for the Terraform remote state backend using S3.

## Overview

The backend infrastructure includes:
- **S3 Bucket**: Stores Terraform state files with versioning enabled
- **Encryption**: Server-side encryption (AES256) for all state files
- **Versioning**: Automatic versioning for state history and rollback
- **Lifecycle Policies**: Automatic cleanup of old versions after 90 days
- **Public Access Block**: Complete protection against public access
- **Object Lock**: Optional governance mode for additional protection

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0.0
- Sufficient AWS permissions to create S3 buckets

## Initial Setup

### Step 1: Initialize and Apply Bootstrap

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

This will create:
- S3 bucket: `thekloudwiz-tf-state-bucket`
- Region: `eu-central-1`
- Encryption: Enabled (AES256)
- Versioning: Enabled

### Step 2: Verify Backend Resources

```bash
# Check bucket exists
aws s3 ls s3://thekloudwiz-tf-state-bucket --region eu-central-1

# Verify versioning is enabled
aws s3api get-bucket-versioning \
  --bucket thekloudwiz-tf-state-bucket \
  --region eu-central-1

# Verify encryption is enabled
aws s3api get-bucket-encryption \
  --bucket thekloudwiz-tf-state-bucket \
  --region eu-central-1
```

### Step 3: Configure Main Infrastructure

After the backend is created, you can initialize your main infrastructure:

```bash
cd ..
terraform init -backend-config=backend/dev.hcl
```

## State Locking

This setup uses **S3's native versioning and consistency** for state management instead of DynamoDB:

- **Versioning**: Every state change creates a new version
- **Consistency**: S3 provides strong read-after-write consistency
- **Rollback**: Previous versions can be restored if needed

### Advantages of S3-only approach:
- ✅ Simpler infrastructure (no DynamoDB table needed)
- ✅ Lower cost (no DynamoDB charges)
- ✅ Built-in versioning for state history
- ✅ Automatic conflict detection via S3 versioning

### Considerations:
- ⚠️ No explicit locking mechanism (rely on S3 consistency)
- ⚠️ Concurrent applies should be avoided via process controls
- ⚠️ Use CI/CD pipelines to serialize deployments

## Backend Configuration Files

The backend configuration is stored in `backend/*.hcl` files:

```hcl
# backend/dev.hcl
bucket  = "thekloudwiz-tf-state-bucket"
key     = "iam-modules/dev-terraform.state"
region  = "eu-central-1"
encrypt = true
```

## State File Organization

State files are organized by environment:

```
s3://thekloudwiz-tf-state-bucket/
├── iam-modules/
│   ├── dev-terraform.state
│   ├── stg-terraform.state
│   ├── qa-terraform.state
│   └── prd-terraform.state
└── logs/
    └── (access logs)
```

## Disaster Recovery

### Backup State Files

State files are automatically versioned in S3. To list versions:

```bash
aws s3api list-object-versions \
  --bucket thekloudwiz-tf-state-bucket \
  --prefix iam-modules/dev-terraform.state \
  --region eu-central-1
```

### Restore Previous Version

To restore a previous version:

```bash
# Download specific version
aws s3api get-object \
  --bucket thekloudwiz-tf-state-bucket \
  --key iam-modules/dev-terraform.state \
  --version-id <VERSION_ID> \
  terraform.tfstate.backup

# Push restored state
terraform state push terraform.tfstate.backup
```

### Manual Backup

Create manual backups before major changes:

```bash
# Pull current state
terraform state pull > backups/terraform.tfstate.$(date +%Y%m%d_%H%M%S).backup
```

## Security Best Practices

1. **Bucket Policy**: Restrict access to specific IAM roles/users
2. **Encryption**: Always use encryption at rest (enabled by default)
3. **Versioning**: Keep versioning enabled for rollback capability
4. **Access Logging**: Monitor bucket access via CloudTrail
5. **MFA Delete**: Consider enabling MFA delete for production

## Maintenance

### Cleanup Old Versions

Old versions are automatically deleted after 90 days via lifecycle policy.

To manually cleanup:

```bash
# List old versions
aws s3api list-object-versions \
  --bucket thekloudwiz-tf-state-bucket \
  --prefix iam-modules/ \
  --region eu-central-1

# Delete specific version
aws s3api delete-object \
  --bucket thekloudwiz-tf-state-bucket \
  --key iam-modules/dev-terraform.state \
  --version-id <VERSION_ID> \
  --region eu-central-1
```

### Monitor Bucket Size

```bash
aws s3 ls s3://thekloudwiz-tf-state-bucket --recursive --summarize
```

## Troubleshooting

### Issue: Bucket already exists

If the bucket already exists (as in this case), you can import it:

```bash
terraform import aws_s3_bucket.terraform_state thekloudwiz-tf-state-bucket
```

### Issue: State file not found

Verify the key path in your backend configuration matches the actual S3 path.

### Issue: Access denied

Ensure your AWS credentials have the necessary S3 permissions:
- `s3:GetObject`
- `s3:PutObject`
- `s3:ListBucket`
- `s3:GetBucketVersioning`

## Migration from Local State

See `../scripts/migrate-state.sh` for automated migration from local to remote state.

## Cost Estimation

Approximate monthly costs (us-east-1 pricing):
- S3 Storage: ~$0.023 per GB
- S3 Requests: Minimal (< $1/month for typical usage)
- Data Transfer: Free within same region

**Estimated total**: < $5/month for typical usage

## References

- [Terraform S3 Backend Documentation](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [S3 Encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html)
