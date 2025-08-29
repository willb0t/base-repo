# Infrastructure-as-Code Repository Makefile
# Provides common tasks for development, testing, and deployment

.PHONY: help setup setup-dev setup-tools clean test lint format security docs deploy destroy validate plan apply

# Default target
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Environment Setup
setup: ## Set up basic Python environment and install core dependencies
	@echo "Setting up Python environment..."
	@chmod +x scripts/setup-python-env-universal.sh
	@./scripts/setup-python-env-universal.sh
	@echo "Core requirements installed."

setup-dev: ## Set up development environment with all dev tools
	@echo "Setting up development environment..."
	@chmod +x scripts/setup-python-env-universal.sh
	@./scripts/setup-python-env-universal.sh --dev

setup-tools: ## Set up environment with all IaC tools
	@echo "Setting up IaC tools environment..."
	@chmod +x scripts/setup-python-env-universal.sh
	@./scripts/setup-python-env-universal.sh --tools

setup-all: ## Set up base environment with core IaC dependencies (no dev tools)
	@echo "Setting up base environment with core dependencies..."
	@chmod +x scripts/setup-python-env-universal.sh
	@./scripts/setup-python-env-universal.sh

setup-legacy: ## Set up using legacy script (original 3-distro support)
	@echo "Setting up Python environment using legacy script..."
	@chmod +x scripts/setup-python-env.sh
	@./scripts/setup-python-env.sh
	@echo "Installing core requirements..."
	@pip install -r requirements.txt

setup-force: ## Force reinstall environment even if it exists
	@echo "Force reinstalling Python environment..."
	@chmod +x scripts/setup-python-env-universal.sh
	@./scripts/setup-python-env-universal.sh --force --all

setup-dev-full: ## Set up development environment with Jupyter/IPython (conflicts with terraform-compliance)
	@echo "Setting up full development environment with modern IPython..."
	@echo "WARNING: This excludes terraform-compliance due to IPython version conflicts"
	@chmod +x scripts/setup-python-env-universal.sh
	@./scripts/setup-python-env-universal.sh --dev-only

setup-compliance: ## Set up environment with compliance tools (terraform-compliance + base requirements)
	@echo "Setting up compliance environment with terraform-compliance..."
	@echo "NOTE: This uses older IPython (7.16.1) for terraform-compliance compatibility"
	@chmod +x scripts/setup-python-env-universal.sh
	@./scripts/setup-python-env-universal.sh --compliance

# Environment Management
clean: ## Clean up Python cache files and temporary directories
	@echo "Cleaning up Python cache files..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -delete
	@find . -type d -name "*.egg-info" -exec rm -rf {} +
	@find . -type f -name ".coverage" -delete
	@find . -type d -name ".pytest_cache" -exec rm -rf {} +
	@find . -type d -name ".tox" -exec rm -rf {} +
	@echo "Cleanup complete."

clean-terraform: ## Clean Terraform state and cache files
	@echo "Cleaning Terraform files..."
	@find . -name ".terraform" -type d -exec rm -rf {} +
	@find . -name "*.tfstate*" -delete
	@find . -name ".terraform.lock.hcl" -delete
	@echo "Terraform cleanup complete."

# Code Quality
test: ## Run all tests
	@echo "Running tests..."
	@pytest tests/ -v --cov=. --cov-report=html --cov-report=term

test-fast: ## Run tests without coverage
	@echo "Running fast tests..."
	@pytest tests/ -v -x

lint: ## Run linting checks
	@echo "Running linting checks..."
	@flake8 scripts/ --max-line-length=88 --extend-ignore=E203,W503
	@pylint scripts/*.py --disable=C0114,C0116
	@ansible-lint ansible/

format: ## Format code using black and isort
	@echo "Formatting Python code..."
	@black scripts/ --line-length=88
	@isort scripts/ --profile=black

security: ## Run security scans
	@echo "Running security scans..."
	@bandit -r scripts/ -f json -o security-report.json || true
	@safety check --json --output security-deps.json || true
	@checkov -d terraform/ --framework terraform --output json --output-file terraform-security.json || true

# Documentation
docs: ## Generate documentation
	@echo "Generating documentation..."
	@mkdir -p docs/generated
	@terraform-docs markdown table terraform/modules/vsphere/ > docs/generated/vsphere-module.md
	@terraform-docs markdown table terraform/modules/proxmox/ > docs/generated/proxmox-module.md

# Terraform Operations
validate: ## Validate Terraform configuration
	@echo "Validating Terraform configuration..."
	@terraform init -backend=false
	@terraform validate
	@terraform fmt -check=true

plan-vsphere: ## Create Terraform plan for vSphere
	@echo "Creating Terraform plan for vSphere..."
	@terraform init
	@terraform plan -var-file=terraform/environments/vsphere.tfvars.example -out=vsphere.tfplan

plan-proxmox: ## Create Terraform plan for Proxmox
	@echo "Creating Terraform plan for Proxmox..."
	@terraform init
	@terraform plan -var-file=terraform/environments/proxmox.tfvars.example -out=proxmox.tfplan

apply-vsphere: ## Apply Terraform plan for vSphere
	@echo "Applying Terraform plan for vSphere..."
	@terraform apply vsphere.tfplan

apply-proxmox: ## Apply Terraform plan for Proxmox
	@echo "Applying Terraform plan for Proxmox..."
	@terraform apply proxmox.tfplan

destroy-vsphere: ## Destroy vSphere infrastructure
	@echo "Destroying vSphere infrastructure..."
	@terraform destroy -var-file=terraform/environments/vsphere.tfvars.example

destroy-proxmox: ## Destroy Proxmox infrastructure
	@echo "Destroying Proxmox infrastructure..."
	@terraform destroy -var-file=terraform/environments/proxmox.tfvars.example

# Ansible Operations
ansible-check: ## Check Ansible playbook syntax
	@echo "Checking Ansible playbook syntax..."
	@ansible-playbook ansible/playbooks/gitlab-setup.yml --syntax-check

ansible-dry-run: ## Run Ansible playbook in dry-run mode
	@echo "Running Ansible playbook in dry-run mode..."
	@ansible-playbook ansible/playbooks/gitlab-setup.yml --check --diff

ansible-deploy: ## Deploy GitLab using Ansible
	@echo "Deploying GitLab using Ansible..."
	@ansible-playbook ansible/playbooks/gitlab-setup.yml

# Vault Operations
vault-create: ## Create new Ansible Vault file
	@echo "Creating new Ansible Vault file..."
	@chmod +x scripts/manage-vault.sh
	@./scripts/manage-vault.sh create

vault-edit: ## Edit Ansible Vault file
	@echo "Editing Ansible Vault file..."
	@chmod +x scripts/manage-vault.sh
	@./scripts/manage-vault.sh edit

vault-view: ## View Ansible Vault file
	@echo "Viewing Ansible Vault file..."
	@chmod +x scripts/manage-vault.sh
	@./scripts/manage-vault.sh view

vault-validate: ## Validate Ansible Vault file
	@echo "Validating Ansible Vault file..."
	@chmod +x scripts/manage-vault.sh
	@./scripts/manage-vault.sh validate

# SSH Key Management
ssh-keys: ## Generate SSH keys for VM access
	@echo "Generating SSH keys..."
	@chmod +x scripts/generate-ssh-keys.sh
	@./scripts/generate-ssh-keys.sh

# Complete Deployment Workflows
deploy-vsphere: validate plan-vsphere apply-vsphere ansible-deploy ## Complete vSphere deployment
	@echo "vSphere deployment completed successfully!"

deploy-proxmox: validate plan-proxmox apply-proxmox ansible-deploy ## Complete Proxmox deployment
	@echo "Proxmox deployment completed successfully!"

# Development Workflows
dev-setup: setup-all ssh-keys vault-create ## Complete development environment setup
	@echo "Development environment setup completed!"

ci-check: lint test security validate ## Run all CI checks
	@echo "All CI checks completed!"

# Monitoring and Status
status: ## Show current infrastructure status
	@echo "=== Terraform Status ==="
	@terraform show -no-color 2>/dev/null || echo "No Terraform state found"
	@echo ""
	@echo "=== Python Environment ==="
	@python --version
	@pip list | grep -E "(ansible|terraform|boto3|pyvmomi|proxmoxer)" || echo "Core packages not installed"

# Backup and Restore
backup: ## Backup important configuration files
	@echo "Creating backup..."
	@mkdir -p backups/$(shell date +%Y%m%d_%H%M%S)
	@cp -r terraform/environments backups/$(shell date +%Y%m%d_%H%M%S)/
	@cp ansible/group_vars/all/vault.yml backups/$(shell date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
	@echo "Backup created in backups/$(shell date +%Y%m%d_%H%M%S)/"

# Update Dependencies
update-deps: ## Update Python dependencies to latest versions
	@echo "Updating Python dependencies..."
	@pip-compile --upgrade requirements.in 2>/dev/null || echo "pip-tools not installed, skipping requirements.txt update"
	@pip install --upgrade -r requirements.txt

# Distribution Testing and Validation
test-distro-detection: ## Test distribution detection without installing packages
	@echo "Testing distribution detection..."
	@chmod +x scripts/setup-python-env-universal.sh
	@./scripts/setup-python-env-universal.sh --skip-system-deps --debug

show-supported-distros: ## Show all supported distributions from database
	@echo "=== Supported Linux Distributions and BSD Systems ==="
	@echo ""
	@echo "BSD Family:"
	@grep "^[^#].*:bsd:" scripts/distro-database.conf | cut -d: -f1 | sort | sed 's/^/  - /'
	@echo ""
	@echo "Arch Linux Family:"
	@grep "^[^#].*:arch:" scripts/distro-database.conf | cut -d: -f1 | sort | sed 's/^/  - /'
	@echo ""
	@echo "RHEL/Red Hat Family:"
	@grep "^[^#].*:rhel:" scripts/distro-database.conf | cut -d: -f1 | sort | sed 's/^/  - /'
	@echo ""
	@echo "Debian Family:"
	@grep "^[^#].*:debian:" scripts/distro-database.conf | cut -d: -f1 | sort | sed 's/^/  - /'
	@echo ""
	@echo "SUSE Family:"
	@grep "^[^#].*:suse:" scripts/distro-database.conf | cut -d: -f1 | sort | sed 's/^/  - /'
	@echo ""
	@echo "Gentoo Family:"
	@grep "^[^#].*:gentoo:" scripts/distro-database.conf | cut -d: -f1 | sort | sed 's/^/  - /'
	@echo ""
	@echo "Slackware Family:"
	@grep "^[^#].*:slackware:" scripts/distro-database.conf | cut -d: -f1 | sort | sed 's/^/  - /'
	@echo ""
	@echo "Independent Distributions:"
	@grep "^[^#].*:independent:" scripts/distro-database.conf | cut -d: -f1 | sort | sed 's/^/  - /'
	@echo ""
	@echo "Total supported distributions: $$(grep -c "^[^#].*:" scripts/distro-database.conf)"

validate-database: ## Validate distribution database format
	@echo "Validating distribution database..."
	@awk -F: 'NF != 6 && !/^#/ && !/^$$/ { print "Invalid format on line " NR ": " $$0; exit 1 }' scripts/distro-database.conf
	@echo "Database format validation passed!"

show-distro-stats: ## Show distribution statistics by family
	@echo "=== Distribution Statistics ==="
	@echo ""
	@echo "By Family:"
	@grep "^[^#].*:" scripts/distro-database.conf | cut -d: -f2 | sort | uniq -c | sort -nr | awk '{printf "  %-12s: %d distributions\n", $$2, $$1}'
	@echo ""
	@echo "By Package Manager:"
	@grep "^[^#].*:" scripts/distro-database.conf | cut -d: -f3 | sort | uniq -c | sort -nr | awk '{printf "  %-12s: %d distributions\n", $$2, $$1}'

# Quick Start
quickstart: ## Quick start guide for new users
	@echo "=== Infrastructure-as-Code Repository Quick Start ==="
	@echo "1. Run 'make dev-setup' to set up your development environment"
	@echo "2. Copy and customize terraform/environments/*.tfvars.example files"
	@echo "3. Run 'make deploy-vsphere' or 'make deploy-proxmox' to deploy"
	@echo "4. Use 'make help' to see all available commands"
	@echo ""
	@echo "Universal Distribution Support:"
	@echo "  - Run 'make show-supported-distros' to see all supported systems"
	@echo "  - Run 'make test-distro-detection' to test detection on your system"
	@echo ""
	@echo "For detailed instructions, see README.md"
