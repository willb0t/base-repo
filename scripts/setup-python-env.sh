#!/bin/bash

# GitLab IaC Multi-Distribution Python Environment Setup
# This script detects Linux distribution and sets up Python virtual environment with IaC tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
VENV_DIR="venv"
PYTHON_MIN_VERSION="3.8"
REQUIREMENTS_DIR="requirements"

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
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN}  GitLab IaC Python Environment Setup          ${NC}"
    echo -e "${CYAN}  Multi-Distribution Support                    ${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo
}

# Detect Linux distribution
detect_distro() {
    local distro=""
    local version=""
    local package_manager=""
    
    # Method 1: Check /etc/os-release
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        distro="$ID"
        version="$VERSION_ID"
    fi
    
    # Method 2: Check specific distribution files
    if [ -z "$distro" ]; then
        if [ -f /etc/arch-release ]; then
            distro="arch"
        elif [ -f /etc/redhat-release ]; then
            distro="rhel"
        elif [ -f /etc/debian_version ]; then
            distro="debian"
        fi
    fi
    
    # Method 3: Check package managers
    if [ -z "$distro" ]; then
        if command -v pacman &> /dev/null; then
            distro="arch"
            package_manager="pacman"
        elif command -v dnf &> /dev/null; then
            distro="rhel"
            package_manager="dnf"
        elif command -v yum &> /dev/null; then
            distro="rhel"
            package_manager="yum"
        elif command -v apt &> /dev/null; then
            distro="debian"
            package_manager="apt"
        fi
    fi
    
    # Normalize distribution names
    case "$distro" in
        ubuntu|debian|linuxmint)
            distro="debian"
            package_manager="apt"
            ;;
        centos|rhel|rocky|almalinux|fedora)
            distro="rhel"
            if command -v dnf &> /dev/null; then
                package_manager="dnf"
            else
                package_manager="yum"
            fi
            ;;
        arch|manjaro|endeavouros)
            distro="arch"
            package_manager="pacman"
            ;;
    esac
    
    echo "$distro:$version:$package_manager"
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_error "This script should not be run as root"
        print_info "Please run as a regular user with sudo privileges"
        exit 1
    fi
}

# Install system dependencies based on distribution
install_system_deps() {
    local distro_info
    distro_info=$(detect_distro)
    local distro=$(echo "$distro_info" | cut -d: -f1)
    local version=$(echo "$distro_info" | cut -d: -f2)
    local package_manager=$(echo "$distro_info" | cut -d: -f3)
    
    print_info "Detected distribution: $distro (using $package_manager)"
    
    case "$distro" in
        debian)
            print_info "Installing system dependencies for Debian-based system..."
            sudo apt update
            
            # Install basic Python and development tools
            sudo apt install -y \
                python3 \
                python3-pip \
                python3-venv \
                python3-dev \
                python3-setuptools \
                python3-wheel \
                build-essential \
                git \
                curl \
                wget \
                unzip \
                software-properties-common \
                apt-transport-https \
                ca-certificates \
                gnupg \
                lsb-release \
                jq \
                tree
            
            # Try to install latest Python if available
            local python_version
            python_version=$(python3 --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
            print_info "Current Python version: $python_version"
            
            # Add deadsnakes PPA for newer Python versions on older Ubuntu
            if command -v lsb_release &> /dev/null; then
                local ubuntu_version
                ubuntu_version=$(lsb_release -rs 2>/dev/null || echo "")
                if [[ "$ubuntu_version" =~ ^(18|20)\. ]]; then
                    print_info "Adding deadsnakes PPA for newer Python versions..."
                    sudo add-apt-repository -y ppa:deadsnakes/ppa || true
                    sudo apt update || true
                    
                    # Try to install Python 3.11 or 3.10
                    for py_ver in 3.11 3.10 3.9; do
                        if sudo apt install -y python${py_ver} python${py_ver}-venv python${py_ver}-dev 2>/dev/null; then
                            print_success "Installed Python $py_ver"
                            # Create symlink for easier access
                            sudo update-alternatives --install /usr/bin/python3-latest python3-latest /usr/bin/python${py_ver} 1 || true
                            break
                        fi
                    done
                fi
            fi
            ;;
            
        rhel)
            print_info "Installing system dependencies for RHEL-based system..."
            
            # Enable EPEL repository
            if command -v dnf &> /dev/null; then
                sudo dnf install -y epel-release || true
                sudo dnf update -y
                sudo dnf install -y \
                    python3 \
                    python3-pip \
                    python3-devel \
                    python3-setuptools \
                    python3-wheel \
                    gcc \
                    gcc-c++ \
                    make \
                    git \
                    curl \
                    wget \
                    unzip \
                    which \
                    jq \
                    tree
            else
                sudo yum install -y epel-release || true
                sudo yum update -y
                sudo yum install -y \
                    python3 \
                    python3-pip \
                    python3-devel \
                    python3-setuptools \
                    python3-wheel \
                    gcc \
                    gcc-c++ \
                    make \
                    git \
                    curl \
                    wget \
                    unzip \
                    which \
                    jq \
                    tree
            fi
            
            # Install python3-venv if available
            if command -v dnf &> /dev/null; then
                sudo dnf install -y python3-venv || print_warning "python3-venv not available, will use pip install virtualenv"
            else
                sudo yum install -y python3-venv || print_warning "python3-venv not available, will use pip install virtualenv"
            fi
            ;;
            
        arch)
            print_info "Installing system dependencies for Arch-based system..."
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm \
                python \
                python-pip \
                python-virtualenv \
                base-devel \
                git \
                curl \
                wget \
                unzip \
                which \
                jq \
                tree
            ;;
            
        *)
            print_error "Unsupported distribution: $distro"
            print_info "Supported distributions: Debian/Ubuntu, RHEL/CentOS/Fedora, Arch Linux"
            print_info "Please install Python 3.8+, pip, and venv manually"
            exit 1
            ;;
    esac
    
    print_success "System dependencies installed successfully"
}

# Check Python version
check_python_version() {
    local python_cmd=""
    
    # Find the best Python command
    for cmd in python3-latest python3.11 python3.10 python3.9 python3; do
        if command -v "$cmd" &> /dev/null; then
            python_cmd="$cmd"
            break
        fi
    done
    
    if [ -z "$python_cmd" ]; then
        print_error "Python 3 not found"
        exit 1
    fi
    
    local python_version
    python_version=$($python_cmd --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
    
    print_info "Using Python: $python_cmd (version $python_version)"
    
    # Check minimum version
    if ! $python_cmd -c "import sys; exit(0 if sys.version_info >= (${PYTHON_MIN_VERSION//./, }) else 1)" 2>/dev/null; then
        print_error "Python $python_version is below minimum required version $PYTHON_MIN_VERSION"
        exit 1
    fi
    
    echo "$python_cmd"
}

# Create virtual environment
create_venv() {
    local python_cmd="$1"
    
    print_info "Creating Python virtual environment..."
    
    # Remove existing venv if it exists
    if [ -d "$VENV_DIR" ]; then
        print_warning "Removing existing virtual environment"
        rm -rf "$VENV_DIR"
    fi
    
    # Create new virtual environment
    if ! $python_cmd -m venv "$VENV_DIR"; then
        print_warning "venv module not available, trying virtualenv..."
        if ! command -v virtualenv &> /dev/null; then
            print_info "Installing virtualenv..."
            $python_cmd -m pip install --user virtualenv
        fi
        virtualenv -p "$python_cmd" "$VENV_DIR"
    fi
    
    print_success "Virtual environment created: $VENV_DIR"
}

# Activate virtual environment and upgrade pip
setup_venv() {
    print_info "Setting up virtual environment..."
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate"
    
    # Upgrade pip, setuptools, and wheel
    print_info "Upgrading pip, setuptools, and wheel..."
    pip install --upgrade pip setuptools wheel
    
    print_success "Virtual environment setup complete"
}

# Install Python packages
install_packages() {
    print_info "Installing Python packages..."
    
    # Install main requirements
    if [ -f "requirements.txt" ]; then
        print_info "Installing main requirements..."
        pip install -r requirements.txt
    fi
    
    # Install development requirements
    if [ -f "requirements-dev.txt" ]; then
        print_info "Installing development requirements..."
        pip install -r requirements-dev.txt
    fi
    
    # Install tool-specific requirements
    if [ -f "requirements-tools.txt" ]; then
        print_info "Installing IaC tool requirements..."
        pip install -r requirements-tools.txt
    fi
    
    print_success "Python packages installed successfully"
}

# Verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    # Check key tools
    local tools=(
        "ansible --version"
        "ansible-playbook --version"
        "pip list | grep -i terraform"
        "python --version"
    )
    
    for tool_check in "${tools[@]}"; do
        if eval "$tool_check" &> /dev/null; then
            print_success "✓ $(echo "$tool_check" | cut -d' ' -f1) is working"
        else
            print_warning "⚠ $(echo "$tool_check" | cut -d' ' -f1) check failed"
        fi
    done
}

# Create activation script
create_activation_script() {
    print_info "Creating activation script..."
    
    cat > activate-env.sh << 'EOF'
#!/bin/bash
# GitLab IaC Python Environment Activation Script

VENV_DIR="venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "Virtual environment not found. Run ./scripts/setup-python-env.sh first"
    exit 1
fi

echo "Activating Python virtual environment..."
source "$VENV_DIR/bin/activate"

echo "Python environment activated!"
echo "Python version: $(python --version)"
echo "Pip version: $(pip --version)"
echo ""
echo "Available tools:"
echo "  - ansible: $(ansible --version | head -1)"
echo "  - terraform tools: $(pip list | grep -i terraform | wc -l) packages"
echo ""
echo "To deactivate, run: deactivate"
EOF
    
    chmod +x activate-env.sh
    print_success "Created activation script: activate-env.sh"
}

# Show usage information
show_usage() {
    echo
    print_success "Python environment setup completed!"
    echo
    print_info "To activate the environment:"
    echo "  source activate-env.sh"
    echo "  # or"
    echo "  source venv/bin/activate"
    echo
    print_info "To deactivate:"
    echo "  deactivate"
    echo
    print_info "To update packages:"
    echo "  source venv/bin/activate"
    echo "  pip install --upgrade -r requirements.txt"
    echo
    print_info "Installed tools include:"
    echo "  - Ansible (with collections)"
    echo "  - Terraform utilities"
    echo "  - Cloud provider tools"
    echo "  - Security scanners"
    echo "  - Development tools"
}

# Main function
main() {
    local skip_system_deps=false
    local force_reinstall=false
    
    print_header
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-system-deps)
                skip_system_deps=true
                shift
                ;;
            --force)
                force_reinstall=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  --skip-system-deps    Skip system package installation"
                echo "  --force               Force reinstall even if venv exists"
                echo "  -h, --help            Show this help message"
                echo
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Check if running as root
    check_root
    
    # Install system dependencies
    if [ "$skip_system_deps" = false ]; then
        install_system_deps
    else
        print_info "Skipping system dependency installation"
    fi
    
    # Check Python version and get command
    local python_cmd
    python_cmd=$(check_python_version)
    
    # Check if virtual environment already exists
    if [ -d "$VENV_DIR" ] && [ "$force_reinstall" = false ]; then
        print_warning "Virtual environment already exists"
        echo -n "Do you want to recreate it? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_info "Using existing virtual environment"
            source "$VENV_DIR/bin/activate"
            install_packages
            verify_installation
            show_usage
            return 0
        fi
    fi
    
    # Create and setup virtual environment
    create_venv "$python_cmd"
    setup_venv
    
    # Install packages
    install_packages
    
    # Verify installation
    verify_installation
    
    # Create activation script
    create_activation_script
    
    # Show usage information
    show_usage
}

# Run main function with all arguments
main "$@"
