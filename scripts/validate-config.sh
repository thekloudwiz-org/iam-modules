#!/bin/bash
# Validate Terraform configuration before applying
# Usage: ./scripts/validate-config.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$PROJECT_DIR"

echo -e "${GREEN}Running Terraform validation checks...${NC}\n"

# Check 1: Terraform format
echo -e "${YELLOW}[1/5] Checking Terraform formatting...${NC}"
if terraform fmt -check -recursive .; then
    echo -e "${GREEN}✓ Formatting check passed${NC}\n"
else
    echo -e "${RED}✗ Formatting issues found. Run: terraform fmt -recursive .${NC}\n"
    exit 1
fi

# Check 2: Terraform validation
echo -e "${YELLOW}[2/5] Validating Terraform configuration...${NC}"
if terraform init -backend=false > /dev/null 2>&1 && terraform validate; then
    echo -e "${GREEN}✓ Configuration is valid${NC}\n"
else
    echo -e "${RED}✗ Configuration validation failed${NC}\n"
    exit 1
fi

# Check 3: Check for sensitive data
echo -e "${YELLOW}[3/5] Checking for sensitive data...${NC}"
if grep -r "ghp_" . --exclude-dir=.git --exclude-dir=.terraform --exclude-dir=docs --exclude="*.md" --exclude="validate-config.sh" 2>/dev/null; then
    echo -e "${RED}✗ Found potential GitHub tokens in files${NC}\n"
    exit 1
else
    echo -e "${GREEN}✓ No sensitive data found${NC}\n"
fi

# Check 4: Validate JSON policy files
echo -e "${YELLOW}[4/5] Validating JSON policy files...${NC}"
INVALID_JSON=0
for file in $(find ./policies -name "*.json" 2>/dev/null); do
    if ! python3 -m json.tool "$file" > /dev/null 2>&1; then
        echo -e "${RED}✗ Invalid JSON: $file${NC}"
        INVALID_JSON=1
    fi
done
if [ $INVALID_JSON -eq 0 ]; then
    echo -e "${GREEN}✓ All JSON files are valid${NC}\n"
else
    exit 1
fi

# Check 5: Backend configuration consistency
echo -e "${YELLOW}[5/5] Checking backend configuration consistency...${NC}"
REGION_MISMATCH=0
for hcl in backend/*.hcl; do
    REGION=$(grep "region" "$hcl" | awk -F'"' '{print $2}' | head -1)
    if [ "$REGION" != "eu-central-1" ]; then
        echo -e "${RED}✗ Region mismatch in $hcl: $REGION (expected: eu-central-1)${NC}"
        REGION_MISMATCH=1
    fi
done
if [ $REGION_MISMATCH -eq 0 ]; then
    echo -e "${GREEN}✓ Backend configurations are consistent${NC}\n"
else
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All validation checks passed! ✓${NC}"
echo -e "${GREEN}========================================${NC}"
