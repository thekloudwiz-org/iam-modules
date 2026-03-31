#!/bin/bash
# Backup Terraform state from S3
# Usage: ./scripts/backup-state.sh <environment>

set -e

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/backups"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p "$BACKUP_DIR"

# Parse backend config
BACKEND_CONFIG="$PROJECT_DIR/backend/$ENVIRONMENT.hcl"
BUCKET=$(grep "bucket" "$BACKEND_CONFIG" | awk -F'"' '{print $2}' | head -1)
REGION=$(grep "region" "$BACKEND_CONFIG" | awk -F'"' '{print $2}' | head -1)
KEY=$(grep "key" "$BACKEND_CONFIG" | awk -F'"' '{print $2}' | head -1)

BACKUP_FILE="$BACKUP_DIR/${ENVIRONMENT}-terraform.tfstate.$(date +%Y%m%d_%H%M%S).backup"

echo -e "${GREEN}Backing up state for $ENVIRONMENT environment...${NC}"
echo "Source: s3://$BUCKET/$KEY"
echo "Destination: $BACKUP_FILE"

# Download state from S3
aws s3 cp "s3://$BUCKET/$KEY" "$BACKUP_FILE" --region "$REGION"

echo -e "${GREEN}Backup completed successfully!${NC}"
echo -e "${YELLOW}Backup location: $BACKUP_FILE${NC}"
