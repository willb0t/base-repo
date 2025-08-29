#!/bin/bash

# GitLab IaC Environment Variable Loader
# This script loads encrypted credentials from Ansible Vault and exports them as environment variables for Terraform

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

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_header() {
    echo -e "${BLUE}========================================${NC}" >&2
    echo -e "${BLUE}  GitLab IaC Environment Loader        ${NC}" >&2
    echo -e "${BLUE}========================================${NC}" >&2
    echo >&2
}

# Check if ansible-vault is available
check_dependencies() {
    if ! command -v ansible-vault &> /dev/null; then
        print_error "ansible-vault is not installed or not in PATH"
        print_info "Please install Ansible first"
        exit 1
    fi
}

# Check if vault files exist
check_vault_files() {
    if [ ! -f "$VAULT_FILE" ]; then
        print_error "Vault file does not exist: $VAULT_FILE"
        print_info "Create it first with: ./scripts/manage-vault.sh create"
        exit 1
    fi
    
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        print_error "Vault password file not found: $VAULT_PASSWORD_FILE"
        print_info "Create vault first with: ./scripts/manage-vault.sh create"
        exit 1
    fi
}

# Load vault variables and convert to environment variables
load_vault_env() {
    local platform="$1"
    local temp_file=$(mktemp)
    
    print_info "Loading vault credentials for platform: ${platform:-all}"
    
    # Decrypt vault file
    if ! ansible-vault view "$VAULT_FILE" --vault-password-file="$VAULT_PASSWORD_FILE" > "$temp_file" 2>/dev/null; then
        print_error "Failed to decrypt vault file"
        rm -f "$temp_file"
        exit 1
    fi
    
    # Convert vault variables to Terraform environment variables
    echo "# Terraform environment variables loaded from Ansible Vault"
    echo "# Generated on: $(date)"
    echo "# Platform: ${platform:-all}"
    echo
    
    # Process each line in the vault file
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*$ ]] || [[ "$line" =~ ^--- ]]; then
            continue
        fi
        
        # Process vault variables
        if [[ "$line" =~ ^[[:space:]]*vault_([^:]+):[[:space:]]*(.+)$ ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local var_value="${BASH_REMATCH[2]}"
            
            # Clean up the value (remove quotes and trim whitespace)
            var_value=$(echo "$var_value" | sed 's/^[[:space:]]*"//; s/"[[:space:]]*$//; s/^[[:space:]]*//; s/[[:space:]]*$//')
            
            # Skip multiline values (they start with |)
            if [[ "$var_value" == "|" ]]; then
                continue
            fi
            
            # Filter based on platform if specified
            if [ -n "$platform" ]; then
                case "$platform" in
                    vsphere)
                        if [[ ! "$var_name" =~ ^(vsphere_|ssh_|gitlab_|ldap_) ]]; then
                            continue
                        fi
                        ;;
                    proxmox)
                        if [[ ! "$var_name" =~ ^(proxmox_|ssh_|gitlab_|ldap_) ]]; then
                            continue
                        fi
                        ;;
                esac
            fi
            
            # Export as Terraform variable
            echo "export TF_VAR_${var_name}=\"${var_value}\""
        fi
    done < "$temp_file"
    
    # Clean up
    rm -f "$temp_file"
    
    echo
    echo "# Usage: source <(./scripts/load-vault-env.sh [platform])"
    echo "# Example: source <(./scripts/load-vault-env.sh vsphere)"
}

# Validate loaded environment variables
validate_env() {
    local platform="$1"
    local missing_vars=()
    
    print_info "Validating environment variables for platform: ${platform:-all}"
    
    case "$platform" in
        vsphere)
            local required_vars=(
                "TF_VAR_vsphere_server"
                "TF_VAR_vsphere_user"
                "TF_VAR_vsphere_password"
            )
            ;;
        proxmox)
            local required_vars=(
                "TF_VAR_proxmox_api_url"
                "TF_VAR_proxmox_api_token_id"
                "TF_VAR_proxmox_api_token"
            )
            ;;
        *)
            local required_vars=(
                "TF_VAR_vsphere_password"
                "TF_VAR_proxmox_api_token"
            )
            ;;
    esac
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        print_warning "Missing environment variables: ${missing_vars[*]}"
        return 1
    else
        print_success "All required environment variables are set"
        return 0
    fi
}

# Show current environment variables
show_env() {
    local platform="$1"
    
    print_info "Current Terraform environment variables:"
    echo
    
    # Show all TF_VAR_ variables
    env | grep "^TF_VAR_" | while IFS= read -r line; do
        local var_name="${line%%=*}"
        local var_value="${line#*=}"
        
        # Filter based on platform if specified
        if [ -n "$platform" ]; then
            case "$platform" in
                vsphere)
                    if [[ ! "$var_name" =~ TF_VAR_(vsphere_|ssh_|gitlab_|ldap_) ]]; then
                        continue
                    fi
                    ;;
                proxmox)
                    if [[ ! "$var_name" =~ TF_VAR_(proxmox_|ssh_|gitlab_|ldap_) ]]; then
                        continue
                    fi
                    ;;
            esac
        fi
        
        # Mask sensitive values
        if [[ "$var_name" =~ (password|token|key) ]]; then
            echo "$var_name=***MASKED***"
        else
            echo "$line"
        fi
    done
    
    if [ -z "$(env | grep "^TF_VAR_")" ]; then
        print_warning "No Terraform environment variables found"
        print_info "Load them with: source <(./scripts/load-vault-env.sh)"
    fi
}

# Clear environment variables
clear_env() {
    print_info "Clearing Terraform environment variables..."
    
    # Get list of TF_VAR_ variables
    local tf_vars
    tf_vars=$(env | grep "^TF_VAR_" | cut -d= -f1)
    
    if [ -n "$tf_vars" ]; then
        echo "# Commands to clear Terraform environment variables"
        echo "$tf_vars" | while read -r var; do
            echo "unset $var"
        done
    else
        print_info "No Terraform environment variables to clear"
    fi
}

# Test connection to platform
test_connection() {
    local platform="$1"
    
    if [ -z "$platform" ]; then
        print_error "Platform not specified for connection test"
        exit 1
    fi
    
    print_info "Testing connection to $platform..."
    
    case "$platform" in
        vsphere)
            if [ -z "$TF_VAR_vsphere_server" ] || [ -z "$TF_VAR_vsphere_user" ] || [ -z "$TF_VAR_vsphere_password" ]; then
                print_error "vSphere credentials not loaded"
                exit 1
            fi
            
            # Test vSphere connection using curl
            if command -v curl &> /dev/null; then
                local response
                response=$(curl -k -s -o /dev/null -w "%{http_code}" \
                    -X POST "https://$TF_VAR_vsphere_server/rest/com/vmware/cis/session" \
                    -u "$TF_VAR_vsphere_user:$TF_VAR_vsphere_password" \
                    --connect-timeout 10)
                
                if [ "$response" = "200" ]; then
                    print_success "vSphere connection successful"
                else
                    print_error "vSphere connection failed (HTTP $response)"
                fi
            else
                print_warning "curl not available, cannot test vSphere connection"
            fi
            ;;
        proxmox)
            if [ -z "$TF_VAR_proxmox_api_url" ] || [ -z "$TF_VAR_proxmox_api_token" ]; then
                print_error "Proxmox credentials not loaded"
                exit 1
            fi
            
            # Test Proxmox connection using curl
            if command -v curl &> /dev/null; then
                local response
                response=$(curl -k -s -o /dev/null -w "%{http_code}" \
                    -H "Authorization: PVEAPIToken=$TF_VAR_proxmox_api_token_id=$TF_VAR_proxmox_api_token" \
                    "$TF_VAR_proxmox_api_url/version" \
                    --connect-timeout 10)
                
                if [ "$response" = "200" ]; then
                    print_success "Proxmox connection successful"
                else
                    print_error "Proxmox connection failed (HTTP $response)"
                fi
            else
                print_warning "curl not available, cannot test Proxmox connection"
            fi
            ;;
        *)
            print_error "Unknown platform: $platform"
            exit 1
            ;;
    esac
}

# Show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [PLATFORM]" >&2
    echo >&2
    echo "Commands:" >&2
    echo "  load [platform]     Load vault variables as environment variables" >&2
    echo "  validate [platform] Validate loaded environment variables" >&2
    echo "  show [platform]     Show current environment variables" >&2
    echo "  clear               Generate commands to clear environment variables" >&2
    echo "  test <platform>     Test connection to platform" >&2
    echo "  help                Show this help message" >&2
    echo >&2
    echo "Platforms:" >&2
    echo "  vsphere             VMware vSphere" >&2
    echo "  proxmox             Proxmox VE" >&2
    echo "  (none)              All platforms" >&2
    echo >&2
    echo "Examples:" >&2
    echo "  source <($0 load vsphere)           # Load vSphere credentials" >&2
    echo "  source <($0 load proxmox)           # Load Proxmox credentials" >&2
    echo "  $0 validate vsphere                 # Validate vSphere variables" >&2
    echo "  $0 test vsphere                     # Test vSphere connection" >&2
    echo "  source <($0 clear)                  # Clear all TF variables" >&2
}

# Main function
main() {
    local command="${1:-load}"
    local platform="$2"
    
    # Don't show header for load command (to avoid polluting environment export)
    if [ "$command" != "load" ]; then
        print_header
    fi
    
    # Check dependencies
    check_dependencies
    
    # Check vault files exist (except for show and clear commands)
    if [ "$command" != "show" ] && [ "$command" != "clear" ] && [ "$command" != "help" ]; then
        check_vault_files
    fi
    
    # Parse command
    case "$command" in
        load)
            load_vault_env "$platform"
            ;;
        validate)
            validate_env "$platform"
            ;;
        show)
            show_env "$platform"
            ;;
        clear)
            clear_env
            ;;
        test)
            if [ -z "$platform" ]; then
                print_error "Platform required for test command"
                show_usage
                exit 1
            fi
            test_connection "$platform"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            echo >&2
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
