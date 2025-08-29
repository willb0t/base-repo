#!/bin/bash

# Universal Multi-Distribution Python Environment Setup
# Supports 100+ Linux distributions and BSD systems using comprehensive detection database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
VENV_DIR="venv"
PYTHON_MIN_VERSION="3.9"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATABASE_FILE="${SCRIPT_DIR}/distro-database.conf"

# Global variables
DETECTED_DISTRO=""
DETECTED_FAMILY=""
DETECTED_PACKAGE_MANAGER=""
DETECTED_PYTHON_CMD=""
DETECTED_PARENT=""

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

print_debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        echo -e "${MAGENTA}[DEBUG]${NC} $1"
    fi
}

print_header() {
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}  Universal Multi-Distribution Python Environment Setup        ${NC}"
    echo -e "${CYAN}  Supporting 100+ Linux Distributions and BSD Systems         ${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo
}

# Load distribution database
load_distro_database() {
    if [[ ! -f "$DATABASE_FILE" ]]; then
        print_error "Distribution database not found: $DATABASE_FILE"
        exit 1
    fi
    
    print_debug "Loading distribution database from $DATABASE_FILE"
}

# Enhanced distribution detection using multiple methods
detect_distro_comprehensive() {
    local distro_id=""
    local family=""
    local package_manager=""
    local python_cmd=""
    local parent=""
    
    print_info "Performing comprehensive distribution detection..."
    
    # Method 1: Check /etc/os-release (most reliable for modern systems)
    if [[ -f /etc/os-release ]]; then
        print_debug "Checking /etc/os-release"
        source /etc/os-release
        local os_id="${ID,,}"  # Convert to lowercase
        local os_id_like="${ID_LIKE,,}"
        
        print_debug "Found ID='$os_id', ID_LIKE='$os_id_like'"
        
        # Try exact match first
        if grep -q "^${os_id}:" "$DATABASE_FILE"; then
            distro_id="$os_id"
        # Try ID_LIKE matches
        elif [[ -n "$os_id_like" ]]; then
            for like_id in $os_id_like; do
                if grep -q "^${like_id}:" "$DATABASE_FILE"; then
                    distro_id="$like_id"
                    break
                fi
            done
        fi
    fi
    
    # Method 2: Check specific distribution release files
    if [[ -z "$distro_id" ]]; then
        print_debug "Checking distribution-specific release files"
        
        # BSD systems
        if command -v freebsd-version &>/dev/null; then
            distro_id="freebsd"
        elif [[ "$(uname -s)" == "OpenBSD" ]]; then
            distro_id="openbsd"
        elif [[ "$(uname -s)" == "NetBSD" ]]; then
            distro_id="netbsd"
        elif [[ "$(uname -s)" == "DragonFly" ]]; then
            distro_id="dragonfly"
        # Linux systems
        elif [[ -f /etc/arch-release ]]; then
            distro_id="arch"
        elif [[ -f /etc/manjaro-release ]]; then
            distro_id="manjaro"
        elif [[ -f /etc/endeavouros-release ]]; then
            distro_id="endeavouros"
        elif [[ -f /etc/garuda-release ]]; then
            distro_id="garuda"
        elif [[ -f /etc/redhat-release ]]; then
            if grep -q "CentOS" /etc/redhat-release; then
                distro_id="centos"
            elif grep -q "AlmaLinux" /etc/redhat-release; then
                distro_id="almalinux"
            elif grep -q "Rocky" /etc/redhat-release; then
                distro_id="rocky"
            elif grep -q "Oracle" /etc/redhat-release; then
                distro_id="oracle"
            else
                distro_id="rhel"
            fi
        elif [[ -f /etc/fedora-release ]]; then
            distro_id="fedora"
        elif [[ -f /etc/debian_version ]]; then
            if [[ -f /etc/linuxmint/info ]]; then
                distro_id="mint"
            elif grep -q "Kali" /etc/os-release 2>/dev/null; then
                distro_id="kali"
            elif grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
                distro_id="ubuntu"
            else
                distro_id="debian"
            fi
        elif [[ -f /etc/SuSE-release ]] || [[ -f /etc/SUSE-brand ]]; then
            distro_id="opensuse"
        elif [[ -f /etc/gentoo-release ]]; then
            distro_id="gentoo"
        elif [[ -f /etc/slackware-version ]]; then
            distro_id="slackware"
        elif [[ -f /etc/alpine-release ]]; then
            distro_id="alpine"
        elif [[ -f /etc/void-release ]]; then
            distro_id="void"
        elif [[ -f /etc/solus-release ]]; then
            distro_id="solus"
        fi
    fi
    
    # Method 3: Package manager detection as fallback
    if [[ -z "$distro_id" ]]; then
        print_debug "Using package manager detection as fallback"
        
        if command -v pkg &>/dev/null && [[ "$(uname -s)" == *"BSD" ]]; then
            distro_id="freebsd"  # Generic BSD
        elif command -v pacman &>/dev/null; then
            distro_id="arch"
        elif command -v dnf &>/dev/null; then
            distro_id="fedora"
        elif command -v yum &>/dev/null; then
            distro_id="rhel"
        elif command -v apt &>/dev/null; then
            distro_id="debian"
        elif command -v zypper &>/dev/null; then
            distro_id="opensuse"
        elif command -v emerge &>/dev/null; then
            distro_id="gentoo"
        elif command -v installpkg &>/dev/null; then
            distro_id="slackware"
        elif command -v apk &>/dev/null; then
            distro_id="alpine"
        elif command -v xbps-install &>/dev/null; then
            distro_id="void"
        elif command -v eopkg &>/dev/null; then
            distro_id="solus"
        elif command -v nix-env &>/dev/null; then
            distro_id="nixos"
        fi
    fi
    
    # Look up distribution in database
    if [[ -n "$distro_id" ]]; then
        local db_line
        db_line=$(grep "^${distro_id}:" "$DATABASE_FILE" 2>/dev/null || true)
        
        if [[ -n "$db_line" ]]; then
            IFS=':' read -r _ family package_manager _ parent python_cmd <<< "$db_line"
            print_success "Detected: $distro_id ($family family)"
            print_debug "Package manager: $package_manager, Python: $python_cmd"
        else
            print_warning "Distribution '$distro_id' not found in database, using fallback detection"
            # Fallback to family detection
            detect_family_fallback "$distro_id"
            return
        fi
    else
        print_error "Unable to detect distribution"
        print_info "Supported distributions include:"
        print_info "- Arch Linux family (Arch, Manjaro, EndeavourOS, Garuda, etc.)"
        print_info "- Debian family (Debian, Ubuntu, Mint, Kali, etc.)"
        print_info "- RHEL family (RHEL, CentOS, Fedora, AlmaLinux, etc.)"
        print_info "- SUSE family (openSUSE, SLES)"
        print_info "- BSD family (FreeBSD, OpenBSD, NetBSD, etc.)"
        print_info "- Independent (NixOS, Void, Alpine, Solus, etc.)"
        exit 1
    fi
    
    # Set global variables
    DETECTED_DISTRO="$distro_id"
    DETECTED_FAMILY="$family"
    DETECTED_PACKAGE_MANAGER="$package_manager"
    DETECTED_PYTHON_CMD="$python_cmd"
    DETECTED_PARENT="$parent"
}

# Fallback family detection for unknown distributions
detect_family_fallback() {
    local distro_id="$1"
    
    print_debug "Using fallback family detection for $distro_id"
    
    if command -v pacman &>/dev/null; then
        DETECTED_FAMILY="arch"
        DETECTED_PACKAGE_MANAGER="pacman"
        DETECTED_PYTHON_CMD="python"
    elif command -v apt &>/dev/null; then
        DETECTED_FAMILY="debian"
        DETECTED_PACKAGE_MANAGER="apt"
        DETECTED_PYTHON_CMD="python3"
    elif command -v dnf &>/dev/null; then
        DETECTED_FAMILY="rhel"
        DETECTED_PACKAGE_MANAGER="dnf"
        DETECTED_PYTHON_CMD="python3"
    elif command -v yum &>/dev/null; then
        DETECTED_FAMILY="rhel"
        DETECTED_PACKAGE_MANAGER="yum"
        DETECTED_PYTHON_CMD="python3"
    elif command -v zypper &>/dev/null; then
        DETECTED_FAMILY="suse"
        DETECTED_PACKAGE_MANAGER="zypper"
        DETECTED_PYTHON_CMD="python3"
    elif command -v pkg &>/dev/null && [[ "$(uname -s)" == *"BSD" ]]; then
        DETECTED_FAMILY="bsd"
        DETECTED_PACKAGE_MANAGER="pkg"
        DETECTED_PYTHON_CMD="python3"
    else
        print_error "Unable to determine package manager"
        exit 1
    fi
    
    DETECTED_DISTRO="$distro_id"
    DETECTED_PARENT="unknown"
}

# Check if running as root
check_root() {
    if [[ "$EUID" -eq 0 ]]; then
        print_error "This script should not be run as root"
        print_info "Please run as a regular user with sudo privileges"
        exit 1
    fi
}

# Install system dependencies based on detected family
install_system_deps() {
    print_info "Installing system dependencies for $DETECTED_FAMILY family ($DETECTED_DISTRO)..."
    
    case "$DETECTED_FAMILY" in
        debian)
            install_debian_deps
            ;;
        rhel)
            install_rhel_deps
            ;;
        arch)
            install_arch_deps
            ;;
        suse)
            install_suse_deps
            ;;
        bsd)
            install_bsd_deps
            ;;
        gentoo)
            install_gentoo_deps
            ;;
        slackware)
            install_slackware_deps
            ;;
        independent)
            install_independent_deps
            ;;
        *)
            print_error "Unsupported distribution family: $DETECTED_FAMILY"
            exit 1
            ;;
    esac
    
    print_success "System dependencies installed successfully"
}

# Debian family package installation
install_debian_deps() {
    print_debug "Installing Debian family dependencies"
    
    sudo apt update
    
    # Core packages
    local packages=(
        python3 python3-pip python3-venv python3-dev python3-setuptools python3-wheel
        build-essential git curl wget unzip software-properties-common
        apt-transport-https ca-certificates gnupg lsb-release jq tree
        libssl-dev libffi-dev libxml2-dev libxslt1-dev libjpeg-dev
        libpq-dev libmysqlclient-dev libsqlite3-dev
    )
    
    sudo apt install -y "${packages[@]}"
    
    # Try to install newer Python versions on older systems
    if command -v lsb_release &>/dev/null; then
        local version
        version=$(lsb_release -rs 2>/dev/null || echo "")
        if [[ "$version" =~ ^(18|20)\. ]]; then
            print_info "Adding deadsnakes PPA for newer Python versions..."
            sudo add-apt-repository -y ppa:deadsnakes/ppa || true
            sudo apt update || true
            
            for py_ver in 3.12 3.11 3.10; do
                if sudo apt install -y python${py_ver} python${py_ver}-venv python${py_ver}-dev 2>/dev/null; then
                    print_success "Installed Python $py_ver"
                    break
                fi
            done
        fi
    fi
}

# RHEL family package installation
install_rhel_deps() {
    print_debug "Installing RHEL family dependencies"
    
    # Enable EPEL repository
    if command -v dnf &>/dev/null; then
        sudo dnf install -y epel-release || true
        sudo dnf update -y
        
        local packages=(
            python3 python3-pip python3-devel python3-setuptools python3-wheel
            gcc gcc-c++ make git curl wget unzip which jq tree
            openssl-devel libffi-devel libxml2-devel libxslt-devel
            postgresql-devel mysql-devel sqlite-devel
        )
        
        sudo dnf install -y "${packages[@]}"
        sudo dnf install -y python3-venv || print_warning "python3-venv not available"
    else
        sudo yum install -y epel-release || true
        sudo yum update -y
        
        local packages=(
            python3 python3-pip python3-devel python3-setuptools python3-wheel
            gcc gcc-c++ make git curl wget unzip which jq tree
            openssl-devel libffi-devel libxml2-devel libxslt-devel
            postgresql-devel mysql-devel sqlite-devel
        )
        
        sudo yum install -y "${packages[@]}"
        sudo yum install -y python3-venv || print_warning "python3-venv not available"
    fi
}

# Arch family package installation
install_arch_deps() {
    print_debug "Installing Arch family dependencies"
    
    sudo pacman -Syu --noconfirm
    
    local packages=(
        python python-pip python-virtualenv base-devel git curl wget unzip
        which jq tree openssl libffi libxml2 libxslt
        postgresql-libs mariadb-libs sqlite
    )
    
    sudo pacman -S --noconfirm "${packages[@]}"
}

# SUSE family package installation
install_suse_deps() {
    print_debug "Installing SUSE family dependencies"
    
    sudo zypper refresh
    
    local packages=(
        python3 python3-pip python3-devel python3-setuptools python3-wheel
        gcc gcc-c++ make git curl wget unzip which jq tree
        libopenssl-devel libffi-devel libxml2-devel libxslt-devel
        postgresql-devel libmysqlclient-devel sqlite3-devel
    )
    
    sudo zypper install -y "${packages[@]}"
    sudo zypper install -y python3-venv || print_warning "python3-venv not available"
}

# BSD family package installation
install_bsd_deps() {
    print_debug "Installing BSD family dependencies"
    
    case "$DETECTED_DISTRO" in
        freebsd|ghostbsd|truenas|nomadbsd|hardenedbsd)
            sudo pkg update
            local packages=(
                python3 py39-pip py39-virtualenv git curl wget unzip
                gmake gcc jq tree openssl libffi libxml2 libxslt
                postgresql13-client mysql80-client sqlite3
            )
            sudo pkg install -y "${packages[@]}"
            ;;
        openbsd)
            sudo pkg_add python3 py3-pip git curl wget unzip gmake gcc jq tree
            ;;
        netbsd)
            sudo pkgin update
            sudo pkgin install python3 py-pip git curl wget unzip gmake gcc jq tree
            ;;
        dragonfly)
            sudo pkg update
            sudo pkg install python3 py-pip git curl wget unzip gmake gcc jq tree
            ;;
        *)
            print_warning "Specific BSD variant not recognized, using generic FreeBSD packages"
            sudo pkg update
            sudo pkg install -y python3 py39-pip py39-virtualenv git curl wget unzip gmake gcc
            ;;
    esac
}

# Gentoo family package installation
install_gentoo_deps() {
    print_debug "Installing Gentoo family dependencies"
    
    sudo emerge --sync
    
    local packages=(
        dev-lang/python dev-python/pip dev-python/virtualenv
        sys-devel/gcc dev-vcs/git net-misc/curl net-misc/wget
        app-arch/unzip sys-apps/which app-misc/jq app-text/tree
        dev-libs/openssl dev-libs/libffi dev-libs/libxml2 dev-libs/libxslt
    )
    
    sudo emerge "${packages[@]}"
}

# Slackware family package installation
install_slackware_deps() {
    print_debug "Installing Slackware family dependencies"
    
    print_warning "Slackware family requires manual package management"
    print_info "Please ensure the following are installed:"
    print_info "- Python 3.9+"
    print_info "- pip"
    print_info "- Development tools (gcc, make)"
    print_info "- Git, curl, wget"
    
    # Basic check for essential tools
    if ! command -v python3 &>/dev/null; then
        print_error "Python 3 not found. Please install Python 3.9+ manually."
        exit 1
    fi
}

# Independent distributions package installation
install_independent_deps() {
    print_debug "Installing packages for independent distribution: $DETECTED_DISTRO"
    
    case "$DETECTED_DISTRO" in
        nixos)
            print_info "NixOS detected - using nix-env for package installation"
            nix-env -iA nixpkgs.python3 nixpkgs.python3Packages.pip nixpkgs.python3Packages.virtualenv
            nix-env -iA nixpkgs.git nixpkgs.curl nixpkgs.wget nixpkgs.unzip nixpkgs.gcc nixpkgs.gnumake
            ;;
        void)
            sudo xbps-install -Syu
            sudo xbps-install -y python3 python3-pip python3-virtualenv git curl wget unzip gcc make jq tree
            ;;
        alpine)
            sudo apk update
            sudo apk add python3 py3-pip python3-dev git curl wget unzip build-base jq tree
            sudo apk add openssl-dev libffi-dev libxml2-dev libxslt-dev
            ;;
        solus)
            sudo eopkg update-repo
            sudo eopkg install python3 python3-devel pip git curl wget unzip gcc make jq tree
            ;;
        clearlinux)
            sudo swupd update
            sudo swupd bundle-add python3-basic dev-utils git curl wget
            ;;
        *)
            print_warning "Independent distribution '$DETECTED_DISTRO' may require manual setup"
            print_info "Please ensure Python 3.9+, pip, and development tools are installed"
            ;;
    esac
}

# Check Python version and find best command
check_python_version() {
    local python_cmd=""
    
    print_info "Checking for suitable Python version..." >&2
    
    # Try different Python commands based on detected system
    local python_candidates=()
    
    case "$DETECTED_FAMILY" in
        arch)
            python_candidates=("python" "python3" "python3.12" "python3.11" "python3.10" "python3.9")
            ;;
        bsd)
            python_candidates=("python3" "python3.9" "python3.10" "python3.11" "python3.12")
            ;;
        *)
            python_candidates=("python3" "python3.12" "python3.11" "python3.10" "python3.9" "python")
            ;;
    esac
    
    for cmd in "${python_candidates[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            local version
            version=$($cmd --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
            print_debug "Found $cmd with version $version" >&2
            
            if $cmd -c "import sys; exit(0 if sys.version_info >= (3, 9) else 1)" 2>/dev/null; then
                python_cmd="$cmd"
                print_success "Using Python: $python_cmd (version $version)" >&2
                break
            fi
        fi
    done
    
    if [[ -z "$python_cmd" ]]; then
        print_error "No suitable Python version found (requires 3.9+)" >&2
        print_info "Please install Python 3.9 or later" >&2
        exit 1
    fi
    
    echo "$python_cmd"
}

# Create virtual environment
create_venv() {
    local python_cmd="$1"
    
    print_info "Creating Python virtual environment..."
    
    # Remove existing venv if it exists
    if [[ -d "$VENV_DIR" ]]; then
        print_warning "Removing existing virtual environment"
        rm -rf "$VENV_DIR"
    fi
    
    # Create new virtual environment
    if ! $python_cmd -m venv "$VENV_DIR"; then
        print_warning "venv module not available, trying virtualenv..."
        if ! command -v virtualenv &>/dev/null; then
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

# Install Python packages with conflict resolution
install_packages() {
    print_info "Installing Python packages..."
    
    # Handle different installation modes
    if [[ "${INSTALL_DEV_ONLY:-}" == "1" ]]; then
        # Development-only mode: Skip terraform-compliance to avoid IPython conflicts
        print_info "Installing development requirements (excluding terraform-compliance)..."
        if [[ -f "requirements-dev.txt" ]]; then
            pip install -r requirements-dev.txt
        fi
        
        # Install base requirements but exclude terraform-compliance
        if [[ -f "requirements.txt" ]]; then
            print_info "Installing base requirements (excluding terraform-compliance)..."
            # Create temporary requirements file without terraform-compliance
            grep -v "terraform-compliance" requirements.txt > /tmp/requirements-no-compliance.txt
            pip install -r /tmp/requirements-no-compliance.txt
            rm -f /tmp/requirements-no-compliance.txt
        fi
        
    elif [[ "${INSTALL_COMPLIANCE:-}" == "1" ]]; then
        # Compliance mode: Install terraform-compliance with compatible IPython
        print_info "Installing compliance requirements with terraform-compliance..."
        if [[ -f "requirements.txt" ]]; then
            pip install -r requirements.txt
        fi
        
        # Install specific IPython version compatible with terraform-compliance
        print_info "Installing IPython 7.16.1 for terraform-compliance compatibility..."
        pip install "IPython==7.16.1"
        
    else
        # Standard installation modes
        # Install main requirements
        if [[ -f "requirements.txt" ]]; then
            print_info "Installing main requirements..."
            pip install -r requirements.txt
        fi
        
        # Install development requirements if requested
        if [[ "${INSTALL_DEV:-}" == "1" ]] && [[ -f "requirements-dev.txt" ]]; then
            print_info "Installing development requirements..."
            pip install -r requirements-dev.txt
        fi
        
        # Install tool-specific requirements if requested
        if [[ "${INSTALL_TOOLS:-}" == "1" ]] && [[ -f "requirements-tools.txt" ]]; then
            print_info "Installing IaC tool requirements..."
            pip install -r requirements-tools.txt
        fi
    fi
    
    print_success "Python packages installed successfully"
}

# Verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    # Check key tools
    local tools=(
        "python --version"
        "pip --version"
        "ansible --version"
    )
    
    for tool_check in "${tools[@]}"; do
        if eval "$tool_check" &>/dev/null; then
            print_success "✓ $(echo "$tool_check" | cut -d' ' -f1) is working"
        else
            print_warning "⚠ $(echo "$tool_check" | cut -d' ' -f1) check failed"
        fi
    done
    
    # Show distribution summary
    print_info "Distribution Summary:"
    print_info "  Detected: $DETECTED_DISTRO"
    print_info "  Family: $DETECTED_FAMILY"
    print_info "  Package Manager: $DETECTED_PACKAGE_MANAGER"
    print_info "  Python Command: $DETECTED_PYTHON_CMD"
}

# Create activation script
create_activation_script() {
    print_info "Creating activation script..."
    
    cat > activate-env.sh << EOF
#!/bin/bash
# Universal Multi-Distribution Python Environment Activation Script

VENV_DIR="venv"

if [[ ! -d "\$VENV_DIR" ]]; then
    echo "Virtual environment not found. Run ./scripts/setup-python-env-universal.sh first"
    exit 1
fi

echo "Activating Python virtual environment..."
source "\$VENV_DIR/bin/activate"

echo "Python environment activated!"
echo "Distribution: $DETECTED_DISTRO ($DETECTED_FAMILY family)"
echo "Python version: \$(python --version)"
echo "Pip version: \$(pip --version)"
echo ""
echo "Available tools:"
if command -v ansible &>/dev/null; then
    echo "  - ansible: \$(ansible --version | head -1)"
fi
echo "  - terraform tools: \$(pip list | grep -i terraform | wc -l) packages"
echo ""
echo "To deactivate, run: deactivate"
EOF
    
    chmod +x activate-env.sh
    print_success "Created activation script: activate-env.sh"
}

# Show usage information
show_usage() {
    echo
    print_success "Universal Python environment setup completed!"
    echo
    print_info "Detected System: $DETECTED_DISTRO ($DETECTED_FAMILY family)"
    echo
    print_info "To activate the environment:"
    echo "  source activate-env.sh"
    echo "  # or"
    echo "  source venv/bin/activate"
    echo
    print_info "To deactivate:"
    echo "  deactivate"
    echo
    print_info "Supported distribution families:"
    echo "  - Arch Linux (100+ distributions)"
    echo "  - Debian/Ubuntu (50+ distributions)"  
    echo "  - RHEL/Fedora (20+ distributions)"
    echo "  - SUSE (openSUSE, SLES)"
    echo "  - BSD (FreeBSD, OpenBSD, NetBSD, etc.)"
    echo "  - Independent (NixOS, Void, Alpine, etc.)"
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
            --dev)
                export INSTALL_DEV=1
                shift
                ;;
            --tools)
                export INSTALL_TOOLS=1
                shift
                ;;
            --all)
                export INSTALL_DEV=1
                export INSTALL_TOOLS=1
                shift
                ;;
            --dev-only)
                export INSTALL_DEV_ONLY=1
                shift
                ;;
            --compliance)
                export INSTALL_COMPLIANCE=1
                shift
                ;;
            --debug)
                export DEBUG=1
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  --skip-system-deps    Skip system package installation"
                echo "  --force               Force reinstall even if venv exists"
                echo "  --dev                 Install development requirements"
                echo "  --tools               Install IaC tools requirements"
                echo "  --all                 Install all requirements (dev + tools)"
                echo "  --dev-only            Install dev requirements with modern IPython (excludes terraform-compliance)"
                echo "  --compliance          Install compliance tools with terraform-compliance (uses IPython 7.16.1)"
                echo "  --debug               Enable debug output"
                echo "  -h, --help            Show this help message"
                echo
                echo "Dependency Conflict Resolution:"
                echo "  Use --dev-only for Jupyter/IPython development (modern IPython 8.18+)"
                echo "  Use --compliance for terraform-compliance checking (IPython 7.16.1)"
                echo "  Standard modes avoid the IPython version conflict"
                echo
                echo "Supported Systems:"
                echo "  - 100+ Linux distributions from DistroWatch"
                echo "  - BSD systems (FreeBSD, OpenBSD, NetBSD, DragonFly)"
                echo "  - Independent distributions (NixOS, Void, Alpine, etc.)"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Load distribution database
    load_distro_database
    
    # Check if running as root
    check_root
    
    # Detect distribution
    detect_distro_comprehensive
    
    # Install system dependencies
    if [[ "$skip_system_deps" == false ]]; then
        install_system_deps
    else
        print_info "Skipping system dependency installation"
    fi
    
    # Check Python version and get command
    local python_cmd
    python_cmd=$(check_python_version)
    
    # Check if virtual environment already exists
    if [[ -d "$VENV_DIR" ]] && [[ "$force_reinstall" == false ]]; then
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
