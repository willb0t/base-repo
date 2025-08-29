#!/bin/bash

# GitLab IaC Environment Setup Script
# This script helps set up the environment for GitLab Infrastructure-as-Code deployment

set -e

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
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  GitLab IaC Environment Setup Script  ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check version of a command
check_version() {
    local cmd="$1"
    local min_version="$2"
    local current_version
    
    case "$cmd" in
        terraform)
            current_version=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4 || echo "unknown")
            ;;
        ansible)
            current_version=$(ansible --version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
            ;;
        *)
            current_version="unknown"
            ;;
    esac
    
    echo "$current_version"
}

# Install Terraform
install_terraform() {
    print_info "Installing Terraform..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux installation
        wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install terraform
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS installation
        if command_exists brew; then
            brew tap hashicorp/tap
            brew install hashicorp/tap/terraform
        else
            print_error "Homebrew not found. Please install Homebrew first or install Terraform manually."
            return 1
        fi
    else
        print_warning "Unsupported OS. Please install Terraform manually from https://www.terraform.io/downloads"
        return 1
    fi
}

# Install Ansible
install_ansible() {
    print_info "Installing Ansible..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux installation
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository --yes --update ppa:ansible/ansible
        sudo apt install -y ansible
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS installation
        if command_exists brew; then
            brew install ansible
        elif command_exists pip3; then
            pip3 install ansible
        else
            print_error "Neither Homebrew nor pip3 found. Please install one of them first."
            return 1
        fi
    else
        print_warning "Unsupported OS. Please install Ansible manually."
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    local missing_deps=()
    local terraform_ok=false
    local ansible_ok=false
    
    # Check Terraform
    if command_exists terraform; then
        local tf_version
        tf_version=$(check_version terraform "1.0")
        print_success "Terraform found: v$tf_version"
        terraform_ok=true
    else
        print_warning "Terraform not found"
        missing_deps+=("terraform")
    fi
    
    # Check Ansible
    if command_exists ansible; then
        local ansible_version
        ansible_version=$(check_version ansible "2.9")
        print_success "Ansible found: v$ansible_version"
        ansible_ok=true
    else
        print_warning "Ansible not found"
        missing_deps+=("ansible")
    fi
    
    # Check Git
    if command_exists git; then
        print_success "Git found: $(git --version)"
    else
        print_warning "Git not found"
        missing_deps+=("git")
    fi
    
    # Check SSH
    if command_exists ssh; then
        print_success "SSH found: $(ssh -V 2>&1 | head -n1)"
    else
        print_warning "SSH not found"
        missing_deps+=("ssh")
    fi
    
    # Offer to install missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo
        print_warning "Missing dependencies: ${missing_deps[*]}"
        echo -n "Would you like to install missing dependencies? (y/N): "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            for dep in "${missing_deps[@]}"; do
                case "$dep" in
                    terraform)
                        install_terraform
                        ;;
                    ansible)
                        install_ansible
                        ;;
                    git)
                        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                            sudo apt install -y git
                        elif [[ "$OSTYPE" == "darwin"* ]] && command_exists brew; then
                            brew install git
                        fi
                        ;;
                    ssh)
                        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                            sudo apt install -y openssh-client
                        elif [[ "$OSTYPE" == "darwin"* ]]; then
                            print_info "SSH should be available by default on macOS"
                        fi
                        ;;
                esac
            done
        fi
    fi
}

# Setup project structure
setup_project() {
    print_info "Setting up project structure..."
    
    # Create necessary directories if they don't exist
    local dirs=(
        "terraform/environments"
        "ansible/inventories"
        "ansible/group_vars"
        "ansible/host_vars"
        "logs"
        ".terraform"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Created directory: $dir"
        fi
    done
    
    # Set proper permissions for SSH directory
    if [ -d "$HOME/.ssh" ]; then
        chmod 700 "$HOME/.ssh"
    else
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        print_success "Created SSH directory: $HOME/.ssh"
    fi
}

# Initialize Terraform
init_terraform() {
    print_info "Initializing Terraform..."
    
    if [ -f "main.tf" ]; then
        terraform init
        print_success "Terraform initialized successfully"
    else
        print_error "main.tf not found. Are you in the correct directory?"
        return 1
    fi
}

# Validate configuration
validate_config() {
    print_info "Validating Terraform configuration..."
    
    if terraform validate; then
        print_success "Terraform configuration is valid"
    else
        print_error "Terraform configuration validation failed"
        return 1
    fi
}

# Setup example configurations
setup_examples() {
    print_info "Setting up example configurations..."
    
    # Copy example files if they don't exist
    if [ ! -f "terraform/environments/vsphere.tfvars" ] && [ -f "terraform/environments/vsphere.tfvars.example" ]; then
        cp "terraform/environments/vsphere.tfvars.example" "terraform/environments/vsphere.tfvars"
        print_success "Created vsphere.tfvars from example"
        print_warning "Please edit terraform/environments/vsphere.tfvars with your environment details"
    fi
    
    if [ ! -f "terraform/environments/proxmox.tfvars" ] && [ -f "terraform/environments/proxmox.tfvars.example" ]; then
        cp "terraform/environments/proxmox.tfvars.example" "terraform/environments/proxmox.tfvars"
        print_success "Created proxmox.tfvars from example"
        print_warning "Please edit terraform/environments/proxmox.tfvars with your environment details"
    fi
}

# Generate SSH keys
generate_ssh_keys() {
    print_info "SSH key generation..."
    
    if [ -f "scripts/generate-ssh-keys.sh" ]; then
        echo -n "Would you like to generate SSH keys for GitLab VM access? (y/N): "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            ./scripts/generate-ssh-keys.sh
        else
            print_info "Skipping SSH key generation"
            print_warning "Make sure to configure SSH keys in your tfvars file"
        fi
    else
        print_warning "SSH key generation script not found"
    fi
}

# Display next steps
display_next_steps() {
    echo
    print_success "Environment setup completed!"
    echo
    print_info "Next steps:"
    echo "==========="
    echo "1. Edit your platform-specific tfvars file:"
    echo "   - For vSphere: terraform/environments/vsphere.tfvars"
    echo "   - For Proxmox: terraform/environments/proxmox.tfvars"
    echo
    echo "2. Configure your platform credentials and settings"
    echo
    echo "3. Deploy infrastructure:"
    echo "   terraform apply -var-file=\"terraform/environments/vsphere.tfvars\""
    echo "   # or"
    echo "   terraform apply -var-file=\"terraform/environments/proxmox.tfvars\""
    echo
    echo "4. Run Ansible playbook:"
    echo "   ansible-playbook -i ansible/inventories/hosts ansible/playbooks/gitlab-setup.yml"
    echo
    echo "5. Access GitLab and complete initial setup"
    echo
    print_info "For detailed instructions, see:"
    echo "- docs/vsphere-setup.md"
    echo "- docs/proxmox-setup.md"
    echo "- docs/troubleshooting.md"
}

# Main function
main() {
    local skip_deps=false
    local skip_terraform=false
    local skip_ssh=false
    
    print_header
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-deps)
                skip_deps=true
                shift
                ;;
            --skip-terraform)
                skip_terraform=true
                shift
                ;;
            --skip-ssh)
                skip_ssh=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  --skip-deps        Skip dependency checking and installation"
                echo "  --skip-terraform   Skip Terraform initialization"
                echo "  --skip-ssh         Skip SSH key generation"
                echo "  -h, --help         Show this help message"
                echo
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    if [ "$skip_deps" = false ]; then
        check_prerequisites
    fi
    
    # Setup project structure
    setup_project
    
    # Initialize Terraform
    if [ "$skip_terraform" = false ]; then
        init_terraform
        validate_config
    fi
    
    # Setup example configurations
    setup_examples
    
    # Generate SSH keys
    if [ "$skip_ssh" = false ]; then
        generate_ssh_keys
    fi
    
    # Display next steps
    display_next_steps
}

# Run main function with all arguments
main "$@"
