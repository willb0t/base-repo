#!/bin/bash

# GitLab IaC SSH Key Generation Script
# This script generates SSH key pairs for GitLab VM access

set -e

# Configuration
KEY_NAME="gitlab-ssh-key"
KEY_TYPE="rsa"
KEY_BITS="4096"
KEY_COMMENT="GitLab IaC SSH Key"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  GitLab IaC SSH Key Generator  ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

# Check if ssh-keygen is available
check_dependencies() {
    if ! command -v ssh-keygen &> /dev/null; then
        print_error "ssh-keygen is not installed or not in PATH"
        exit 1
    fi
}

# Generate SSH key pair
generate_keys() {
    local key_path="$1"
    
    print_info "Generating SSH key pair..."
    print_info "Key type: $KEY_TYPE"
    print_info "Key bits: $KEY_BITS"
    print_info "Key path: $key_path"
    
    # Generate the key pair
    ssh-keygen -t "$KEY_TYPE" -b "$KEY_BITS" -C "$KEY_COMMENT" -f "$key_path" -N ""
    
    if [ $? -eq 0 ]; then
        print_success "SSH key pair generated successfully!"
    else
        print_error "Failed to generate SSH key pair"
        exit 1
    fi
}

# Set proper permissions
set_permissions() {
    local key_path="$1"
    
    print_info "Setting proper permissions..."
    
    # Set permissions for private key (600)
    chmod 600 "$key_path"
    
    # Set permissions for public key (644)
    chmod 644 "$key_path.pub"
    
    print_success "Permissions set correctly"
}

# Display key information
display_key_info() {
    local key_path="$1"
    
    echo
    print_info "SSH Key Information:"
    echo "===================="
    echo "Private key: $key_path"
    echo "Public key:  $key_path.pub"
    echo
    
    print_info "Public key content:"
    echo "-------------------"
    cat "$key_path.pub"
    echo
    
    print_info "Key fingerprint:"
    echo "---------------"
    ssh-keygen -lf "$key_path.pub"
    echo
}

# Update terraform variables
update_terraform_vars() {
    local key_path="$1"
    local public_key_content
    
    public_key_content=$(cat "$key_path.pub")
    
    print_info "Terraform variable configuration:"
    echo "================================"
    echo "Add the following to your terraform.tfvars file:"
    echo
    echo "ssh_public_key       = \"$public_key_content\""
    echo "ssh_private_key_file = \"$key_path\""
    echo
}

# Main function
main() {
    local key_path
    local overwrite="no"
    
    print_header
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                KEY_NAME="$2"
                shift 2
                ;;
            -t|--type)
                KEY_TYPE="$2"
                shift 2
                ;;
            -b|--bits)
                KEY_BITS="$2"
                shift 2
                ;;
            -f|--force)
                overwrite="yes"
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  -n, --name NAME    Key name (default: $KEY_NAME)"
                echo "  -t, --type TYPE    Key type (default: $KEY_TYPE)"
                echo "  -b, --bits BITS    Key bits (default: $KEY_BITS)"
                echo "  -f, --force        Overwrite existing keys"
                echo "  -h, --help         Show this help message"
                echo
                echo "Examples:"
                echo "  $0                           # Generate with defaults"
                echo "  $0 -n my-gitlab-key         # Custom key name"
                echo "  $0 -t ed25519                # Use Ed25519 key type"
                echo "  $0 -f                        # Force overwrite existing keys"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Set key path
    key_path="$HOME/.ssh/$KEY_NAME"
    
    # Check dependencies
    check_dependencies
    
    # Check if keys already exist
    if [[ -f "$key_path" || -f "$key_path.pub" ]]; then
        if [[ "$overwrite" != "yes" ]]; then
            print_warning "SSH keys already exist at $key_path"
            echo -n "Do you want to overwrite them? (y/N): "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                print_info "Operation cancelled"
                exit 0
            fi
        fi
        print_warning "Overwriting existing SSH keys..."
        rm -f "$key_path" "$key_path.pub"
    fi
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # Generate keys
    generate_keys "$key_path"
    
    # Set permissions
    set_permissions "$key_path"
    
    # Display information
    display_key_info "$key_path"
    
    # Show terraform configuration
    update_terraform_vars "$key_path"
    
    print_success "SSH key generation completed!"
    print_info "You can now use these keys with your GitLab IaC deployment"
}

# Run main function with all arguments
main "$@"
