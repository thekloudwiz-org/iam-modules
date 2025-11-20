#!/bin/bash

# Script to migrate from local state to remote S3 backend
# Usage: ./scripts/migrate-state.sh <environment>

set -e

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Migrating Terraform state to remote backend for environment: $ENVIRONMENT${NC}"

# Check if backend config exists
BACKEND_CONFIG="$PROJECT_DIR/backend/$ENVIRONMENT.hcl"
if [ ! -f "$BACKEND_CONFIG" ]; then
    echo -e "${RED}Error: Backend configuration file $BACKEND_CONFIG not found${NC}"
    exit 1
fi

# Check if local state exists
LOCAL_STATE="$PROJECT_DIR/terraform.tfstate"
if [ ! -f "$LOCAL_STATE" ]; then
    echo -e "${YELLOW}Warning: No local state file found. Initializing with remote backend only.${NC}"
fi

# Change to project directory
cd "$PROJECT_DIR"

echo -e "${GREEN}Step 1: Backing up current state (if exists)${NC}"
if [ -f "$LOCAL_STATE" ]; then
    cp "$LOCAL_STATE" "terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Local state backed up"
fi

echo -e "${GREEN}Step 2: Initializing with remote backend${NC}"
terraform init -backend-config="$BACKEND_CONFIG"

echo -e "${GREEN}Step 3: Verifying remote state${NC}"
terraform state list

echo -e "${GREEN}Migration completed successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Verify that all resources are present in the remote state"
echo "2. Test with 'terraform plan' to ensure no unexpected changes"
echo "3. Remove local state files if everything looks correct"
echo "4. Update your team about the new remote state location"

echo -e "\n${GREEN}Remote state location:${NC}"
echo "Bucket: thekloudwiz-tf-state-bucket"
echo "Key: iam-modules/$ENVIRONMENT-terraform.state"
echo "Region: us-east-1"
