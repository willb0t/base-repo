#!/bin/bash

# GitLab IaC Ansible Vault Management Script
# This script helps create and manage encrypted credential files using Ansible Vault

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VAULT_DIR="ansible/group_vars/all"
VAULT_FILE="$VAULT_DIR/vault.yml"
VAULT_PASSWORD_FILE=".vault_password"
BACKUP_DIR="vault_backups"

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  GitLab IaC Vault Management Script   ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
}

# Check if ansible-vault is available
check_dependencies() {
    if ! command -v ansible-vault &> /dev/null; then
        print_error "ansible-vault is not installed or not in PATH"
        print_info "Please install Ansible first"
        exit 1
    fi
}

# Create vault password file
create_vault_password() {
    if [ -f "$VAULT_PASSWORD_FILE" ]; then
        print_warning "Vault password file already exists"
        echo -n "Do you want to create a new password? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    print_info "Creating vault password file..."
    
    # Generate a secure random password
    if command -v openssl &> /dev/null; then
        openssl rand -base64 32 > "$VAULT_PASSWORD_FILE"
    elif command -v head &> /dev/null && [ -f /dev/urandom ]; then
        head -c 32 /dev/urandom | base64 > "$VAULT_PASSWORD_FILE"
    else
        print_error "Cannot generate secure password. Please install openssl or ensure /dev/urandom is available"
        exit 1
    fi
    
    # Set secure permissions
    chmod 600 "$VAULT_PASSWORD_FILE"
    
    print_success "Vault password file created: $VAULT_PASSWORD_FILE"
    print_warning "IMPORTANT: Keep this password file secure and do NOT commit it to git!"
    print_info "Password: $(cat $VAULT_PASSWORD_FILE)"
}

# Create vault directory structure
create_vault_structure() {
    print_info "Creating vault directory structure..."
    
    mkdir -p "$VAULT_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        touch .gitignore
    fi
    
    # Add vault password file to .gitignore
    if ! grep -q "$VAULT_PASSWORD_FILE" .gitignore; then
        echo "$VAULT_PASSWORD_FILE" >> .gitignore
        print_success "Added $VAULT_PASSWORD_FILE to .gitignore"
    fi
    
    # Add backup directory to .gitignore
    if ! grep -q "$BACKUP_DIR/" .gitignore; then
        echo "$BACKUP_DIR/" >> .gitignore
        print_success "Added $BACKUP_DIR/ to .gitignore"
    fi
}

# Create vault template
create_vault_template() {
    local temp_file=$(mktemp)
    
    cat > "$temp_file" << 'EOF'
---
# Encrypted credentials for GitLab IaC deployment
# This file contains sensitive information and is encrypted with Ansible Vault

# VMware vSphere Credentials
vault_vsphere_server: "vcenter.example.com"
vault_vsphere_user: "administrator@vsphere.local"
vault_vsphere_password: "your-secure-vcenter-password"

# Proxmox Credentials
vault_proxmox_api_url: "https://proxmox.example.com:8006/api2/json"
vault_proxmox_api_token_id: "terraform@pve!terraform"
vault_proxmox_api_token: "your-secure-proxmox-api-token"

# LDAP Credentials (Optional)
vault_ldap_bind_dn: "cn=admin,dc=example,dc=com"
vault_ldap_password: "your-secure-ldap-password"

# GitLab Configuration
vault_gitlab_initial_root_password: "your-secure-gitlab-root-password"

# SSH Keys (if using existing keys)
vault_ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  # Your private SSH key content here
  -----END OPENSSH PRIVATE KEY-----

vault_ssh_public_key: "ssh-rsa AAAAB3NzaC1yc2E... your-public-key"

# Database Passwords (for advanced configurations)
vault_postgresql_password: "your-secure-db-password"
vault_redis_password: "your-secure-redis-password"

# SSL Certificate Information (if using custom certificates)
vault_ssl_certificate: |
  -----BEGIN CERTIFICATE-----
  # Your SSL certificate content here
  -----END CERTIFICATE-----

vault_ssl_private_key: |
  -----BEGIN PRIVATE KEY-----
  # Your SSL private key content here
  -----END PRIVATE KEY-----
EOF
    
    echo "$temp_file"
}

# Create new vault file
create_vault() {
    print_info "Creating new vault file..."
    
    if [ -f "$VAULT_FILE" ]; then
        print_warning "Vault file already exists: $VAULT_FILE"
        echo -n "Do you want to overwrite it? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_info "Operation cancelled"
            return 0
        fi
        
        # Backup existing vault
        backup_vault
    fi
    
    # Create vault password if it doesn't exist
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        create_vault_password
    fi
    
    # Create directory structure
    create_vault_structure
    
    # Create template and encrypt it
    local temp_file
    temp_file=$(create_vault_template)
    
    print_info "Creating encrypted vault file..."
    ansible-vault create "$VAULT_FILE" --vault-password-file="$VAULT_PASSWORD_FILE" < "$temp_file"
    
    # Clean up temp file
    rm "$temp_file"
    
    print_success "Vault file created: $VAULT_FILE"
    print_info "You can now edit it with: $0 edit"
}

# Edit vault file
edit_vault() {
    if [ ! -f "$VAULT_FILE" ]; then
        print_error "Vault file does not exist: $VAULT_FILE"
        print_info "Create it first with: $0 create"
        exit 1
    fi
    
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        print_error "Vault password file not found: $VAULT_PASSWORD_FILE"
        exit 1
    fi
    
    print_info "Opening vault file for editing..."
    ansible-vault edit "$VAULT_FILE" --vault-password-file="$VAULT_PASSWORD_FILE"
}

# View vault file
view_vault() {
    if [ ! -f "$VAULT_FILE" ]; then
        print_error "Vault file does not exist: $VAULT_FILE"
        exit 1
    fi
    
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        print_error "Vault password file not found: $VAULT_PASSWORD_FILE"
        exit 1
    fi
    
    print_info "Viewing vault file contents..."
    ansible-vault view "$VAULT_FILE" --vault-password-file="$VAULT_PASSWORD_FILE"
}

# Backup vault file
backup_vault() {
    if [ ! -f "$VAULT_FILE" ]; then
        print_warning "No vault file to backup"
        return 0
    fi
    
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/vault_${timestamp}.yml"
    
    mkdir -p "$BACKUP_DIR"
    cp "$VAULT_FILE" "$backup_file"
    
    print_success "Vault backed up to: $backup_file"
}

# Validate vault file
validate_vault() {
    if [ ! -f "$VAULT_FILE" ]; then
        print_error "Vault file does not exist: $VAULT_FILE"
        exit 1
    fi
    
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        print_error "Vault password file not found: $VAULT_PASSWORD_FILE"
        exit 1
    fi
    
    print_info "Validating vault file..."
    
    # Check if file is properly encrypted
    if ansible-vault view "$VAULT_FILE" --vault-password-file="$VAULT_PASSWORD_FILE" > /dev/null 2>&1; then
        print_success "Vault file is valid and properly encrypted"
        
        # Check for required variables
        local temp_content
        temp_content=$(ansible-vault view "$VAULT_FILE" --vault-password-file="$VAULT_PASSWORD_FILE")
        
        local required_vars=(
            "vault_vsphere_password"
            "vault_proxmox_api_token"
        )
        
        local missing_vars=()
        for var in "${required_vars[@]}"; do
            if ! echo "$temp_content" | grep -q "^$var:"; then
                missing_vars+=("$var")
            fi
        done
        
        if [ ${#missing_vars[@]} -gt 0 ]; then
            print_warning "Missing recommended variables: ${missing_vars[*]}"
        else
            print_success "All recommended variables are present"
        fi
    else
        print_error "Vault file validation failed"
        exit 1
    fi
}

# Change vault password
change_password() {
    if [ ! -f "$VAULT_FILE" ]; then
        print_error "Vault file does not exist: $VAULT_FILE"
        exit 1
    fi
    
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        print_error "Vault password file not found: $VAULT_PASSWORD_FILE"
        exit 1
    fi
    
    print_info "Changing vault password..."
    
    # Backup current vault
    backup_vault
    
    # Create new password file
    local new_password_file="${VAULT_PASSWORD_FILE}.new"
    
    if command -v openssl &> /dev/null; then
        openssl rand -base64 32 > "$new_password_file"
    else
        head -c 32 /dev/urandom | base64 > "$new_password_file"
    fi
    
    chmod 600 "$new_password_file"
    
    # Change vault password
    ansible-vault rekey "$VAULT_FILE" --vault-password-file="$VAULT_PASSWORD_FILE" --new-vault-password-file="$new_password_file"
    
    # Replace old password file
    mv "$new_password_file" "$VAULT_PASSWORD_FILE"
    
    print_success "Vault password changed successfully"
    print_info "New password: $(cat $VAULT_PASSWORD_FILE)"
}

# Export environment variables
export_env() {
    if [ ! -f "$VAULT_FILE" ]; then
        print_error "Vault file does not exist: $VAULT_FILE"
        exit 1
    fi
    
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        print_error "Vault password file not found: $VAULT_PASSWORD_FILE"
        exit 1
    fi
    
    print_info "Exporting vault variables as environment variables..."
    
    # Create temporary script
    local temp_script=$(mktemp)
    
    # Decrypt vault and convert to environment variables
    ansible-vault view "$VAULT_FILE" --vault-password-file="$VAULT_PASSWORD_FILE" | \
    grep -E "^vault_" | \
    sed 's/^vault_/export TF_VAR_/g' | \
    sed 's/: /=/g' | \
    sed 's/"//g' > "$temp_script"
    
    echo "# Source this file to load vault variables as environment variables"
    echo "# Usage: source <(./scripts/manage-vault.sh export-env)"
    echo
    cat "$temp_script"
    
    rm "$temp_script"
}

# Show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  create          Create a new vault file with template"
    echo "  edit            Edit the vault file"
    echo "  view            View the vault file contents"
    echo "  validate        Validate the vault file"
    echo "  backup          Backup the vault file"
    echo "  change-password Change the vault password"
    echo "  export-env      Export vault variables as environment variables"
    echo "  help            Show this help message"
    echo
    echo "Examples:"
    echo "  $0 create                    # Create new vault file"
    echo "  $0 edit                      # Edit vault file"
    echo "  $0 view                      # View vault contents"
    echo "  source <($0 export-env)      # Load variables into shell"
}

# Main function
main() {
    print_header
    
    # Check dependencies
    check_dependencies
    
    # Parse command
    case "${1:-help}" in
        create)
            create_vault
            ;;
        edit)
            edit_vault
            ;;
        view)
            view_vault
            ;;
        validate)
            validate_vault
            ;;
        backup)
            backup_vault
            ;;
        change-password)
            change_password
            ;;
        export-env)
            export_env
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
