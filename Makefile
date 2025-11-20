.PHONY: help init validate plan apply apply-all destroy destroy-all destroy-tp destroy-repo destroy-oidc destroy-roles check-policies create-repo update-tp update-xr create-permissions destroy-all-repos apply-org apply-teams apply-oidc apply-permissions apply-roles apply-repos apply-repo apply-teams-repo apply-trust-policy apply-all destroy-org destroy-teams destroy-oidc destroy-permissions destroy-roles destroy-repos destroy-repo destroy-trust-policy destroy-all dev qa stg prd

PROJECT := thekloudwiz
ENVIRONMENTS := dev qa stg prd

# Color output
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[1;33m
NC := \033[0m

# Help target
help:
	@echo -e "$(GREEN)Available targets:$(NC)"
	@echo -e "  $(YELLOW)init [env]$(NC)            - Initialize Terraform with remote state (optionally for specific environment)"
	@echo -e "  $(YELLOW)validate$(NC)              - Validate Terraform configuration"
	@echo -e "  $(YELLOW)plan$(NC)                  - Plan all resources using all tfvars"
	@echo -e "  $(YELLOW)plan-<env>$(NC)            - Plan environment-specific resources"
	@echo -e "\n$(GREEN)Apply targets:$(NC)"
	@echo -e "  $(YELLOW)apply-org$(NC)             - Apply only GitHub organization changes"
	@echo -e "  $(YELLOW)apply-teams$(NC)           - Apply only teams"
	@echo -e "  $(YELLOW)apply-oidc$(NC)            - Apply only OIDC provider"
	@echo -e "  $(YELLOW)apply-permissions$(NC)     - Apply only permissions"
	@echo -e "  $(YELLOW)apply-roles-<env>$(NC)     - Apply roles for a specific environment"
	@echo -e "  $(YELLOW)apply-repos$(NC)           - Apply only repositories"
	@echo -e "  $(YELLOW)apply-repo$(NC)            - Apply only a specific repository"
	@echo -e "  $(YELLOW)apply-teams-repo$(NC)      - Apply only teams and repositories"
	@echo -e "  $(YELLOW)apply-trust-policy-<env>$(NC) - Apply trust policies for a specific environment"
	@echo -e "  $(YELLOW)apply-all$(NC)             - Apply all modules"
	@echo -e "\n$(GREEN)Destroy targets:$(NC)"
	@echo -e "  $(YELLOW)destroy-org$(NC)           - Destroy GitHub organization resources"
	@echo -e "  $(YELLOW)destroy-teams$(NC)         - Destroy teams"
	@echo -e "  $(YELLOW)destroy-oidc$(NC)          - Destroy OIDC resources"
	@echo -e "  $(YELLOW)destroy-permissions$(NC)   - Destroy permissions"
	@echo -e "  $(YELLOW)destroy-roles-<env>$(NC)   - Destroy IAM roles for a specific environment"
	@echo -e "  $(YELLOW)destroy-repos$(NC)         - Destroy all repositories"
	@echo -e "  $(YELLOW)destroy-repo <repo>$(NC)   - Destroy specific repository"
	@echo -e "  $(YELLOW)destroy-trust-policy-<env>$(NC) - Revert trust policies for a specific environment"
	@echo -e "  $(YELLOW)destroy-all$(NC)           - Destroy all resources"
	@echo -e "\n$(GREEN)Utility targets:$(NC)"
	@echo -e "  $(YELLOW)check-policies$(NC)        - Validate IAM policy files"
	@echo -e "  $(YELLOW)fmt$(NC)                   - Format Terraform files"
	@echo -e "  $(YELLOW)clean$(NC)                 - Clean Terraform cache files"

# Initialize Terraform with remote state backend
init:
	@if [ "$(word 2,$(MAKECMDGOALS))" = "" ]; then \
		echo -e "$(GREEN)Initializing Terraform with dev backend (default)...$(NC)"; \
		terraform init -backend-config=backend/dev.hcl; \
	else \
		env="$(word 2,$(MAKECMDGOALS))"; \
		echo -e "$(GREEN)Initializing Terraform for $$env environment with remote state...$(NC)"; \
		if [ ! -f "backend/$$env.hcl" ]; then \
			echo -e "$(RED)Error: Backend configuration file backend/$$env.hcl not found$(NC)"; \
			exit 1; \
		fi; \
		terraform init -backend-config=backend/$$env.hcl; \
	fi

# Validate configuration
validate:
	@echo -e "$(GREEN)Validating Terraform configuration...$(NC)"
	@terraform validate

# Plan all changes (OIDC provider and permissions only)
plan:
	@echo -e "$(GREEN)Planning OIDC provider and permissions changes...$(NC)"
	@terraform plan -var-file=global.tfvars -target=module.oidc_provider -target=module.permissions


# Plan environment-specific changes
plan-%:
	@env="$*"; \
	echo -e "$(GREEN)Planning environment-specific changes for $$env...$(NC)"; \
	terraform plan -var-file=environments/$$env.tfvars -var-file=global.tfvars \

# Apply only GitHub organization changes
apply-org:
	@echo -e "$(GREEN)Applying only GitHub organization changes...$(NC)"
	@terraform apply -var-file=global.tfvars -target=module.organization

# Apply only teams
apply-teams:
	@echo -e "$(GREEN)Applying only teams...$(NC)"
	@terraform apply -var-file=global.tfvars -target=module.teams

# Apply only OIDC provider
apply-oidc:
	@echo -e "$(GREEN)Applying only OIDC provider...$(NC)"
	@terraform apply -var-file=global.tfvars -target=module.oidc_provider

# Apply only permissions
apply-permissions:
	@echo -e "$(GREEN)Applying only permissions...$(NC)"
	@terraform apply -var-file=global.tfvars -target=module.permissions

# Apply roles for a specific environment
apply-roles-%:
	@env="$*"; \
	echo -e "$(GREEN)Applying roles for $env environment...$(NC)"; \
	terraform apply -var-file=environments/$env.tfvars -var-file=global.tfvars -target=module.roles

# Apply only repositories
apply-repos:
	@echo -e "$(GREEN)Applying only repositories...$(NC)"
	@terraform apply -var-file=global.tfvars -target=module.repositories

# Apply only a specific repository
apply-repo:
	@if [ "$(word 2,$(MAKECMDGOALS))" = "" ]; then \
		echo -e "$(RED)Please specify a repository name: make apply-repo <repo-name>$(NC)"; \
		exit 1; \
	else \
		repo="$(word 2,$(MAKECMDGOALS))"; \
		echo -e "$(GREEN)Applying repository $repo...$(NC)"; \
		terraform apply -var-file=global.tfvars -target="module.repositories.github_repository.repos[\"$repo\"]"; \
	fi

# Apply only teams and repositories
apply-teams-repo:
	@echo -e "$(GREEN)Applying only teams and repositories...$(NC)"
	@terraform apply -var-file=global.tfvars -target=module.teams -target=module.repositories

# Apply trust policies for a specific environment
apply-trust-policy-%:
	@env="$*"; \
	echo -e "$(GREEN)Applying trust policies for $env environment...$(NC)"; \
	terraform apply -var-file=environments/$env.tfvars -var-file=global.tfvars -target=module.trust_policies

# Apply all modules
apply-all:
	@echo -e "$(GREEN)Applying all modules...$(NC)"
	@terraform apply -var-file=global.tfvars

# Apply environment-specific changes only (no repos, no trust policies)
apply-%-roles:
	@env="$*"; \
	echo -e "$(GREEN)Applying environment-specific changes for $$env...$(NC)"; \
	terraform apply -auto-approve -var-file=environments/$$env.tfvars -var-file=global.tfvars \
		-target=module.roles -target=module.permissions

# Create only GitHub repositories and update trust policies
create-repo:
	@echo -e "$(GREEN)Creating GitHub repositories and updating trust policies...$(NC)"
	@terraform apply -auto-approve -var-file=global.tfvars -target=module.repositories 
	

# Update trust policies for a specific environment
update-tp-%:
	@env="$*"; \
	echo -e "$(GREEN)Updating trust policies for $env environment...$(NC)"; \
	terraform apply -auto-approve -var-file=environments/$env.tfvars -var-file=global.tfvars -target=module.trust_policies

# Update trust policies with external repository
update-xr:
	@echo -e "$(GREEN)Updating trust policies with external repositories...$(NC)"
	@terraform apply -auto-approve -var-file=x-repos.tfvars -target=module.trust_policies

# Apply just the policies module
create-permissions:
	@echo -e "$(GREEN)Creatin permissions...$(NC)"
	@terraform apply -auto-approve -var-file=global.tfvars -target=module.permissions

# Destroy GitHub organization resources
destroy-org:
	@echo -e "$(RED)WARNING: This will destroy GitHub organization resources!$(NC)"
	@read -p "Type 'destroy-org' to confirm: " confirm; \
	if [ "$confirm" = "destroy-org" ]; then \
		echo -e "$(RED)Destroying GitHub organization resources...$(NC)"; \
		terraform destroy -auto-approve -var-file=global.tfvars -target=module.organization; \
	else \
		echo -e "$(YELLOW)Operation cancelled.$(NC)"; \
	fi

# Destroy teams
destroy-teams:
	@echo -e "$(RED)WARNING: This will destroy teams!$(NC)"
	@read -p "Type 'destroy-teams' to confirm: " confirm; \
	if [ "$confirm" = "destroy-teams" ]; then \
		echo -e "$(RED)Destroying teams...$(NC)"; \
		terraform destroy -auto-approve -var-file=global.tfvars -target=module.teams; \
	else \
		echo -e "$(YELLOW)Operation cancelled.$(NC)"; \
	fi

# Destroy OIDC resources
destroy-oidc:
	@echo -e "$(RED)WARNING: This will destroy OIDC resources!$(NC)"
	@read -p "Type 'destroy-oidc' to confirm: " confirm; \
	if [ "$confirm" = "destroy-oidc" ]; then \
		echo -e "$(RED)Destroying OIDC resources...$(NC)"; \
		terraform destroy -auto-approve -var-file=global.tfvars -target=module.oidc_provider; \
	else \
		echo -e "$(YELLOW)Operation cancelled.$(NC)"; \
	fi

# Destroy permissions
destroy-permissions:
	@echo -e "$(RED)WARNING: This will destroy permissions!$(NC)"
	@read -p "Type 'destroy-permissions' to confirm: " confirm; \
	if [ "$confirm" = "destroy-permissions" ]; then \
		echo -e "$(RED)Destroying permissions...$(NC)"; \
		terraform destroy -auto-approve -var-file=global.tfvars -target=module.permissions; \
	else \
		echo -e "$(YELLOW)Operation cancelled.$(NC)"; \
	fi

# Destroy IAM roles for a specific environment
destroy-roles-%:
	@env="$*"; \
	echo -e "$(RED)WARNING: This will destroy IAM roles for $env environment!$(NC)"; \
	read -p "Type 'destroy-roles-$env' to confirm: " confirm; \
	if [ "$confirm" = "destroy-roles-$env" ]; then \
		echo -e "$(RED)Destroying IAM roles for $env environment...$(NC)"; \
		terraform destroy -auto-approve -var-file=environments/$env.tfvars -var-file=global.tfvars -target=module.roles; \
	else \
		echo -e "$(YELLOW)Operation cancelled.$(NC)"; \
	fi

# Destroy all repositories
destroy-repos:
	@echo -e "$(RED)WARNING: This will destroy ALL repositories!$(NC)"
	@read -p "Type 'destroy-repos' to confirm: " confirm; \
	if [ "$confirm" = "destroy-repos" ]; then \
		echo -e "$(RED)Destroying all repositories...$(NC)"; \
		terraform destroy -auto-approve -var-file=global.tfvars -target=module.repositories; \
	else \
		echo -e "$(YELLOW)Operation cancelled.$(NC)"; \
	fi

# Destroy trust policies for a specific environment
destroy-trust-policy-%:
	@env="$*"; \
	echo -e "$(RED)WARNING: This will revert trust policies for $env environment!$(NC)"; \
	read -p "Type 'destroy-trust-policy-$env' to confirm: " confirm; \
	if [ "$confirm" = "destroy-trust-policy-$env" ]; then \
		echo -e "$(RED)Reverting trust policies for $env environment...$(NC)"; \
		terraform destroy -auto-approve -var-file=environments/$env.tfvars -var-file=global.tfvars -target=module.trust_policies; \
	else \
		echo -e "$(YELLOW)Operation cancelled.$(NC)"; \
	fi

# Destroy all resources
destroy-all:
	@echo -e "$(RED)WARNING: This will destroy ALL resources!$(NC)"
	@read -p "Type 'destroy-all' to confirm: " confirm; \
	if [ "$confirm" = "destroy-all" ]; then \
		echo -e "$(RED)Destroying all resources...$(NC)"; \
		terraform destroy -auto-approve -var-file=global.tfvars; \
	else \
		echo -e "$(YELLOW)Destruction cancelled.$(NC)"; \
	fi

# Destroy environment-specific resources
destroy-%:
	@env="$*"; \
	if [[ "$env" =~ ^(org|teams|oidc|permissions|roles|repos|trust-policy|all)$ ]]; then \
		echo -e "$(YELLOW)Use the dedicated target for this resource.$(NC)"; \
	else \
		echo -e "$(RED)WARNING: This will destroy environment-specific resources for $env!$(NC)"; \
		read -p "Type '$env-destroy' to confirm: " confirm; \
		if [ "$confirm" = "$env-destroy" ]; then \
			echo -e "$(RED)Destroying environment-specific resources...$(NC)"; \
			terraform destroy -auto-approve -var-file=environments/$env.tfvars -var-file=global.tfvars \
				-target=module.roles -target=module.permissions -target=module.oidc_provider; \
		else \
			echo -e "$(YELLOW)Destruction cancelled.$(NC)"; \
		fi; \
	fi

# Destroy specific repository
destroy-repo:
	@if [ "$(word 2,$(MAKECMDGOALS))" = "" ]; then \
		echo -e "$(RED)Please specify a repository name: make destroy-repo <repo-name>$(NC)"; \
		exit 1; \
	else \
		repo="$(word 2,$(MAKECMDGOALS))"; \
		echo -e "$(RED)WARNING: This will destroy repository $repo!$(NC)"; \
		read -p "Type 'destroy-$repo' to confirm: " confirm && \
		if [ "$confirm" = "destroy-$repo" ]; then \
			echo -e "$(RED)Destroying repository $repo...$(NC)"; \
			terraform destroy -auto-approve -var-file=global.tfvars \
				-target="module.repositories.github_repository.repos[\"$repo\"]"; \
		else \
			echo -e "$(YELLOW)Operation cancelled.$(NC)"; \
		fi; \
	fi

# Check all policy files are valid JSON
check-policies:
	@echo -e "$(GREEN)Validating IAM policy files...$(NC)"
	@find ./policies -name "*.json" | while read file; do \
		echo -n "Checking $$file... "; \
		if jq empty "$$file" 2>/dev/null; then \
			echo -e "$(GREEN)✓$(NC)"; \
		else \
			echo -e "$(RED)✗$(NC)"; \
			exit 1; \
		fi \
	done
	@echo -e "$(GREEN)All policy files are valid!$(NC)"

# Utility targets
fmt:
	@echo -e "$(GREEN)Formatting Terraform files...$(NC)"
	@terraform fmt -recursive .

clean:
	@echo -e "$(YELLOW)Cleaning Terraform cache files...$(NC)"
	@rm -rf .terraform
	@rm -f .terraform.lock.hcl
	@echo -e "$(GREEN)Clean complete$(NC)"

# Handle environment targets
$(ENVIRONMENTS):
	@:

# Handle unknown targets
%:
	@: