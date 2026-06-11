.PHONY: help init validate plan apply backup restore migrate check-policies fmt clean

PROJECT := thekloudwiz
ENVIRONMENTS := dev qa stg prd

# Color output
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

# Help target
help:
	@printf "$(GREEN)╔════════════════════════════════════════╗$(NC)\n"
	@printf "$(GREEN)║  IAM Modules - Makefile Commands      ║$(NC)\n"
	@printf "$(GREEN)╚════════════════════════════════════════╝$(NC)\n\n"
	@printf "$(BLUE)Environment Management:$(NC)\n"
	@printf "  $(YELLOW)make init <env>$(NC)              Initialize with remote state (dev, stg, qa, prd)\n"
	@printf "  $(YELLOW)make plan-<env>$(NC)              Plan changes for environment\n"
	@printf "  $(YELLOW)make apply-<env>$(NC)             Apply changes for environment\n\n"
	@printf "$(BLUE)State Management:$(NC)\n"
	@printf "  $(YELLOW)make backup <env>$(NC)            Backup state file\n"
	@printf "  $(YELLOW)make restore <file>$(NC)          Restore state from backup\n"
	@printf "  $(YELLOW)make migrate <env>$(NC)           Migrate local state to remote\n\n"
	@printf "$(BLUE)Validation & Formatting:$(NC)\n"
	@printf "  $(YELLOW)make validate$(NC)                Validate configuration\n"
	@printf "  $(YELLOW)make validate-all$(NC)            Run all validation checks\n"
	@printf "  $(YELLOW)make fmt$(NC)                     Format Terraform files\n"
	@printf "  $(YELLOW)make check-policies$(NC)          Validate JSON policy files\n\n"
	@printf "$(BLUE)Module-Specific Operations:$(NC)\n"
	@printf "  $(YELLOW)make apply-org$(NC)               Apply GitHub organization\n"
	@printf "  $(YELLOW)make apply-teams$(NC)             Apply teams\n"
	@printf "  $(YELLOW)make apply-oidc$(NC)              Apply OIDC provider\n"
	@printf "  $(YELLOW)make apply-permissions$(NC)       Apply IAM permissions\n"
	@printf "  $(YELLOW)make apply-roles-<env>$(NC)       Apply IAM roles for environment\n"
	@printf "  $(YELLOW)make apply-repos$(NC)             Apply repositories\n"
	@printf "  $(YELLOW)make apply-trust-policy-<env>$(NC) Apply trust policies\n\n"
	@printf "$(BLUE)Utility:$(NC)\n"
	@printf "  $(YELLOW)make setup-token$(NC)             Setup GitHub token permanently\n"
	@printf "  $(YELLOW)make clean$(NC)                   Clean Terraform cache\n"
	@printf "  $(YELLOW)make help$(NC)                    Show this help message\n\n"
	@printf "$(BLUE)Examples:$(NC)\n"
	@printf "  make init dev                  # Initialize dev environment\n"
	@printf "  make plan-dev                  # Plan dev changes\n"
	@printf "  make backup dev                # Backup dev state\n"
	@printf "  make apply-dev                 # Apply dev changes\n\n"

# Initialize Terraform with remote state backend
init:
	@if [ "$(word 2,$(MAKECMDGOALS))" = "" ]; then \
		echo -e "$(RED)Error: Please specify environment: make init <env>$(NC)\n"; \
		echo -e "$(YELLOW)Available environments: dev, stg, qa, prd$(NC)\n"; \
		exit 1; \
	fi
	@env="$(word 2,$(MAKECMDGOALS))"; \
	echo -e "$(GREEN)Initializing Terraform for $$env environment...$(NC)\n"; \
	if [ ! -f "backend/$$env.hcl" ]; then \
		echo -e "$(RED)Error: Backend configuration backend/$$env.hcl not found$(NC)\n"; \
		exit 1; \
	fi; \
	terraform init -backend-config=backend/$$env.hcl -reconfigure

# Validate configuration
validate:
	@printf "$(GREEN)Validating Terraform configuration...$(NC)\n"
	@terraform validate

# Run all validation checks
validate-all:
	@printf "$(GREEN)Running comprehensive validation...$(NC)\n"
	@./scripts/validate-config.sh

# Plan environment-specific changes
plan-%:
	@env="$*"; \
	echo -e "$(GREEN)Planning changes for $$env environment...$(NC)\n"; \
	if [ ! -f "environments/$$env.tfvars" ]; then \
		echo -e "$(RED)Error: Environment file environments/$$env.tfvars not found$(NC)\n"; \
		exit 1; \
	fi; \
	terraform plan -var-file=environments/$$env.tfvars -var-file=global.tfvars -var-file=x-repos.tfvars

# Apply environment-specific changes
apply-%:
	@env="$*"; \
	echo -e "$(YELLOW)WARNING: This will apply changes to $$env environment$(NC)\n"; \
	read -p "Continue? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo -e "$(GREEN)Applying changes for $$env environment...$(NC)\n"; \
		terraform apply -auto-approve -var-file=environments/$$env.tfvars -var-file=global.tfvars -var-file=x-repos.tfvars; \
	else \
		echo -e "$(YELLOW)Operation cancelled$(NC)\n"; \
	fi

# Backup state
backup:
	@if [ "$(word 2,$(MAKECMDGOALS))" = "" ]; then \
		echo -e "$(RED)Error: Please specify environment: make backup <env>$(NC)\n"; \
		exit 1; \
	fi
	@env="$(word 2,$(MAKECMDGOALS))"; \
	echo -e "$(GREEN)Backing up state for $$env environment...$(NC)\n"; \
	./scripts/backup-state.sh $$env

# Restore state
restore:
	@if [ "$(word 2,$(MAKECMDGOALS))" = "" ]; then \
		echo -e "$(RED)Error: Please specify backup file: make restore <file>$(NC)\n"; \
		exit 1; \
	fi
	@file="$(word 2,$(MAKECMDGOALS))"; \
	echo -e "$(YELLOW)WARNING: This will restore state from backup$(NC)\n"; \
	./scripts/restore-state.sh $$file

# Migrate local state to remote
migrate:
	@if [ "$(word 2,$(MAKECMDGOALS))" = "" ]; then \
		echo -e "$(RED)Error: Please specify environment: make migrate <env>$(NC)\n"; \
		exit 1; \
	fi
	@env="$(word 2,$(MAKECMDGOALS))"; \
	echo -e "$(GREEN)Migrating state for $$env environment...$(NC)\n"; \
	./scripts/migrate-state.sh $$env

# Apply only GitHub organization
apply-org:
	@printf "$(GREEN)Applying GitHub organization...$(NC)\n"
	@terraform apply -auto-approve -var-file=global.tfvars -target=module.organization

# Apply only teams
apply-teams:
	@printf "$(GREEN)Applying teams...$(NC)\n"
	@terraform apply -auto-approve -var-file=global.tfvars -target=module.teams

# Apply only OIDC provider
apply-oidc:
	@printf "$(GREEN)Applying OIDC provider...$(NC)\n"
	@terraform apply -auto-approve -var-file=global.tfvars -target=module.oidc_provider

# Apply only permissions
apply-permissions:
	@printf "$(GREEN)Applying IAM permissions...$(NC)\n"
	@terraform apply -auto-approve -var-file=global.tfvars -target=module.permissions

# Apply roles for specific environment
apply-roles-%:
	@env="$*"; \
	echo -e "$(GREEN)Applying IAM roles for $$env environment...$(NC)\n"; \
	terraform apply -auto-approve -var-file=environments/$$env.tfvars -var-file=global.tfvars -target=module.roles

# Apply only repositories
apply-repos:
	@printf "$(GREEN)Applying repositories...$(NC)\n"
	@terraform apply -auto-approve -var-file=global.tfvars -target=module.repositories

# Apply trust policies for specific environment
apply-trust-policy-%:
	@env="$*"; \
	echo -e "$(GREEN)Applying trust policies for $$env environment...$(NC)\n"; \
	terraform apply -auto-approve -var-file=environments/$$env.tfvars -var-file=global.tfvars -target=module.trust_policies

# Check all policy files are valid JSON
check-policies:
	@printf "$(GREEN)Validating IAM policy files...$(NC)\n"
	@find ./policies -name "*.json" 2>/dev/null | while read file; do \
		echo -n "Checking $$file... "; \
		if python3 -m json.tool "$$file" > /dev/null 2>&1; then \
			echo -e "$(GREEN)✓$(NC)\n"; \
		else \
			echo -e "$(RED)✗$(NC)\n"; \
			exit 1; \
		fi \
	done
	@printf "$(GREEN)All policy files are valid!$(NC)\n"

# Format Terraform files
fmt:
	@printf "$(GREEN)Formatting Terraform files...$(NC)\n"
	@terraform fmt -recursive .

# Clean Terraform cache
clean:
	@printf "$(YELLOW)Cleaning Terraform cache files...$(NC)\n"
	@rm -rf .terraform
	@rm -f .terraform.lock.hcl
	@printf "$(GREEN)Clean complete$(NC)\n"

# Handle environment targets (dummy targets to prevent errors)
$(ENVIRONMENTS):
	@:

# Handle unknown targets
%:
	@:

# Setup GitHub token permanently
setup-token:
	@printf "$(GREEN)Setting up GitHub token...$(NC)\n"
	@./scripts/setup-github-token.sh
