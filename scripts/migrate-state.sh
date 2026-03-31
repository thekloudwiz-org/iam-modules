#!/bin/bash

# Enhanced script to migrate from local state to remote S3 backend
# Usage: ./scripts/migrate-state.sh <environment> [--dry-run]

set -e

ENVIRONMENT=${1:-dev}
DRY_RUN=${2}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/backups"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Validation functions
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        log_warn "jq is not installed (optional but recommended for JSON parsing)"
    fi
    
    log_info "All prerequisites met"
}

check_backend_config() {
    log_step "Validating backend configuration..."
    
    BACKEND_CONFIG="$PROJECT_DIR/backend/$ENVIRONMENT.hcl"
    if [ ! -f "$BACKEND_CONFIG" ]; then
        log_error "Backend configuration file $BACKEND_CONFIG not found"
        exit 1
    fi
    
    # Parse backend config
    BUCKET=$(grep "bucket" "$BACKEND_CONFIG" | awk -F'"' '{print $2}' | head -1)
    REGION=$(grep "region" "$BACKEND_CONFIG" | awk -F'"' '{print $2}' | head -1)
    KEY=$(grep "key" "$BACKEND_CONFIG" | awk -F'"' '{print $2}' | head -1)
    
    log_info "Backend config: bucket=$BUCKET, region=$REGION, key=$KEY"
    
    # Check if backend is enabled in provider.tf
    if grep -q "^[[:space:]]*#[[:space:]]*backend" "$PROJECT_DIR/provider.tf"; then
        log_error "Backend is commented out in provider.tf"
        log_info "Please uncomment the backend configuration block"
        exit 1
    fi
}

check_aws_resources() {
    log_step "Checking AWS resources..."
    
    # Check if S3 bucket exists
    if aws s3 ls "s3://$BUCKET" --region "$REGION" &> /dev/null; then
        log_info "S3 bucket $BUCKET exists"
        
        # Check versioning
        VERSIONING=$(aws s3api get-bucket-versioning --bucket "$BUCKET" --region "$REGION" 2>/dev/null | grep -o '"Status": "[^"]*"' | cut -d'"' -f4)
        if [ "$VERSIONING" = "Enabled" ]; then
            log_info "Bucket versioning is enabled ✓"
        else
            log_warn "Bucket versioning is not enabled - consider enabling it"
        fi
        
        # Check encryption
        if aws s3api get-bucket-encryption --bucket "$BUCKET" --region "$REGION" &> /dev/null; then
            log_info "Bucket encryption is enabled ✓"
        else
            log_warn "Bucket encryption is not enabled - consider enabling it"
        fi
    else
        log_error "S3 bucket $BUCKET does not exist in region $REGION"
        log_info "Please create the bucket first by running: cd bootstrap && terraform apply"
        exit 1
    fi
}

create_backup() {
    log_step "Creating backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    LOCAL_STATE="$PROJECT_DIR/terraform.tfstate"
    if [ -f "$LOCAL_STATE" ]; then
        BACKUP_FILE="$BACKUP_DIR/terraform.tfstate.$(date +%Y%m%d_%H%M%S).backup"
        cp "$LOCAL_STATE" "$BACKUP_FILE"
        log_info "Local state backed up to $BACKUP_FILE"
        
        # Also backup .terraform directory
        if [ -d "$PROJECT_DIR/.terraform" ]; then
            tar -czf "$BACKUP_DIR/.terraform.$(date +%Y%m%d_%H%M%S).tar.gz" -C "$PROJECT_DIR" .terraform 2>/dev/null || true
            log_info "Terraform directory backed up"
        fi
    else
        log_warn "No local state file found"
    fi
}

migrate_state() {
    log_step "Migrating state to remote backend..."
    
    cd "$PROJECT_DIR"
    
    if [ "$DRY_RUN" = "--dry-run" ]; then
        log_info "DRY RUN: Would initialize with backend config: $BACKEND_CONFIG"
        return
    fi
    
    # Initialize with backend config
    if [ -f "$LOCAL_STATE" ]; then
        log_info "Migrating existing local state to remote backend..."
        terraform init -backend-config="$BACKEND_CONFIG" -migrate-state
    else
        log_info "Initializing with remote backend (no local state to migrate)..."
        terraform init -backend-config="$BACKEND_CONFIG"
    fi
    
    log_info "State migration completed"
}

verify_migration() {
    log_step "Verifying migration..."
    
    cd "$PROJECT_DIR"
    
    # List resources in remote state
    RESOURCE_COUNT=$(terraform state list 2>/dev/null | wc -l | tr -d ' ')
    log_info "Found $RESOURCE_COUNT resources in remote state"
    
    # Verify state file exists in S3
    if aws s3 ls "s3://$BUCKET/$KEY" --region "$REGION" &> /dev/null; then
        log_info "State file exists in S3: s3://$BUCKET/$KEY ✓"
        
        # Get state file size
        SIZE=$(aws s3 ls "s3://$BUCKET/$KEY" --region "$REGION" | awk '{print $3}')
        log_info "State file size: $SIZE bytes"
    else
        log_error "State file not found in S3"
        exit 1
    fi
    
    # Run terraform plan to check for drift
    log_step "Running terraform plan to verify state..."
    if terraform plan -detailed-exitcode -var-file="environments/$ENVIRONMENT.tfvars" -var-file="global.tfvars" &> /dev/null; then
        log_info "No drift detected - migration successful! ✓"
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 2 ]; then
            log_warn "Drift detected - please review with 'terraform plan'"
        else
            log_error "Plan failed - please review the configuration"
        fi
    fi
}

cleanup_local_state() {
    log_step "Cleaning up local state files..."
    
    read -p "Remove local state files? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        rm -f "$PROJECT_DIR/terraform.tfstate"
        rm -f "$PROJECT_DIR/terraform.tfstate.backup"
        log_info "Local state files removed"
    else
        log_info "Local state files preserved"
    fi
}

print_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Migration Summary${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "Environment:     ${BLUE}$ENVIRONMENT${NC}"
    echo -e "Backend Bucket:  ${BLUE}$BUCKET${NC}"
    echo -e "Backend Region:  ${BLUE}$REGION${NC}"
    echo -e "State Key:       ${BLUE}$KEY${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Verify state with: terraform state list"
    echo "2. Test with: terraform plan"
    echo "3. Inform team about remote state location"
    echo "4. Update documentation"
    echo ""
    echo -e "${YELLOW}Rollback Instructions:${NC}"
    echo "If you need to rollback:"
    echo "1. Find backup in: $BACKUP_DIR"
    echo "2. Run: terraform state push <backup-file>"
    echo ""
    echo -e "${YELLOW}State Versioning:${NC}"
    echo "View state versions with:"
    echo "aws s3api list-object-versions --bucket $BUCKET --prefix $KEY --region $REGION"
    echo ""
}

# Main execution
main() {
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Terraform State Migration Tool       ║${NC}"
    echo -e "${GREEN}║  Environment: $(printf '%-24s' $ENVIRONMENT) ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    check_prerequisites
    check_backend_config
    check_aws_resources
    create_backup
    migrate_state
    
    if [ "$DRY_RUN" != "--dry-run" ]; then
        verify_migration
        cleanup_local_state
    fi
    
    print_summary
}

# Run main function
main
