#!/bin/bash

# Script to set up GitHub token permanently
# Usage: ./scripts/setup-github-token.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}GitHub Token Setup${NC}\n"

# Check if token is already set
if [ ! -z "$TF_VAR_github_token" ]; then
    echo -e "${YELLOW}GitHub token is already set in current session${NC}"
    echo "Current token: ${TF_VAR_github_token:0:10}..."
    read -p "Do you want to update it? (yes/no): " update
    if [ "$update" != "yes" ]; then
        echo "Setup cancelled"
        exit 0
    fi
fi

# Prompt for token
echo -e "${YELLOW}Enter your GitHub Personal Access Token:${NC}"
echo "(Get one from: https://github.com/settings/tokens)"
read -s github_token

if [ -z "$github_token" ]; then
    echo -e "${RED}Error: Token cannot be empty${NC}"
    exit 1
fi

# Determine shell config file
if [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_CONFIG="$HOME/.bash_profile"
else
    echo -e "${RED}Error: Could not find shell configuration file${NC}"
    exit 1
fi

echo -e "\n${GREEN}Found shell config: $SHELL_CONFIG${NC}"

# Check if token already exists in config
if grep -q "TF_VAR_github_token" "$SHELL_CONFIG"; then
    echo -e "${YELLOW}Token already exists in $SHELL_CONFIG${NC}"
    read -p "Do you want to replace it? (yes/no): " replace
    if [ "$replace" = "yes" ]; then
        # Remove old token
        sed -i.bak '/TF_VAR_github_token/d' "$SHELL_CONFIG"
        echo -e "${GREEN}Old token removed${NC}"
    else
        echo "Setup cancelled"
        exit 0
    fi
fi

# Add token to shell config
echo "" >> "$SHELL_CONFIG"
echo "# Terraform GitHub Token" >> "$SHELL_CONFIG"
echo "export TF_VAR_github_token=\"$github_token\"" >> "$SHELL_CONFIG"

echo -e "${GREEN}✓ Token added to $SHELL_CONFIG${NC}"

# Export for current session
export TF_VAR_github_token="$github_token"

echo -e "${GREEN}✓ Token exported for current session${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Reload your shell: source $SHELL_CONFIG"
echo "2. Or open a new terminal"
echo "3. Verify with: echo \$TF_VAR_github_token"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
