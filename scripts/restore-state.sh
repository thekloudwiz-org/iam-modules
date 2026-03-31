#!/bin/bash
# Restore Terraform state from backup
# Usage: ./scripts/restore-state.sh <backup-file>

set -e

BACKUP_FILE=${1}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file not specified${NC}"
    echo "Usage: $0 <backup-file>"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

echo -e "${YELLOW}WARNING: This will replace the current state with the backup!${NC}"
echo "Backup file: $BACKUP_FILE"
read -p "Are you sure? Type 'restore' to confirm: " confirm

if [ "$confirm" != "restore" ]; then
    echo -e "${YELLOW}Restore cancelled${NC}"
    exit 0
fi

echo -e "${GREEN}Restoring state from backup...${NC}"
terraform state push "$BACKUP_FILE"

echo -e "${GREEN}State restored successfully!${NC}"
echo -e "${YELLOW}Please verify with: terraform plan${NC}"
