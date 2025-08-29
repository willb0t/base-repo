# Python Environment Setup Guide

This document provides comprehensive information about setting up and managing Python environments for the Infrastructure-as-Code (IaC) repository across different Linux distributions.

## Overview

The repository includes a sophisticated Python environment management system that automatically detects your Linux distribution and sets up the appropriate Python environment with all necessary IaC tools. The system supports **100+ Linux distributions and BSD systems** using a comprehensive detection database:

### **Supported Distribution Families:**

- **BSD Family** (9 distributions): FreeBSD, OpenBSD, NetBSD, DragonFlyBSD, GhostBSD, TrueNAS, NomadBSD, MidnightBSD, HardenedBSD
- **Arch Linux Family** (18+ distributions): Arch Linux, Manjaro, EndeavourOS, Garuda, CachyOS, ArcoLinux, Artix, RebornOS, Archcraft, ArchBang, Bluestar, SDesk, Ultimate, AxOS, Mabox, blendOS, and more
- **RHEL/Red Hat Family** (10+ distributions): RHEL, CentOS, AlmaLinux, Rocky Linux, Oracle Linux, Scientific Linux, Fedora, Nobara, Ultramarine, Bazzite
- **Debian Family** (40+ distributions): 
  - Pure Debian: Debian, Devuan, antiX, MX Linux, SparkyLinux, Q4OS, Peppermint
  - Ubuntu-based: Ubuntu (all flavors), Linux Mint, Pop!_OS, elementary OS, Zorin OS, KDE neon, Feren OS, Lite, Bodhi Linux, TUXEDO OS
  - Security: Kali Linux, Parrot Security
  - Other derivatives: deepin, PikaOS, Nitrux, MiniOS, Voyager, Endless, and more
- **SUSE Family** (4 distributions): openSUSE (Leap, Tumbleweed), SLES
- **Gentoo Family** (4 distributions): Gentoo Linux, Calculate Linux, Sabayon/Redcore Linux
- **Slackware Family** (5 distributions): Slackware, Porteus, PorteuX, Zenwalk, Salix
- **Independent Distributions** (15+ distributions): NixOS, Void Linux, Alpine Linux, Solus, PCLinuxOS, Mageia, 4MLinux, Tiny Core Linux, Clear Linux, KaOS, OpenMandriva, and more

### **Package Manager Support:**
- **apt** (Debian/Ubuntu family)
- **pacman** (Arch family)
- **dnf/yum** (RHEL/Fedora family)
- **zypper** (SUSE family)
- **pkg/ports** (BSD family)
- **emerge** (Gentoo family)
- **installpkg** (Slackware family)
- **apk** (Alpine Linux)
- **xbps** (Void Linux)
- **eopkg** (Solus)
- **nix** (NixOS)
- And many more specialized package managers

## Quick Start

### Automated Setup

The easiest way to set up your Python environment is using the automated script:

```bash
# Make the script executable
chmod +x scripts/setup-python-env.sh

# Run the setup script
./scripts/setup-python-env.sh

# Or use the Makefile
make setup
```

### Manual Setup

If you prefer manual control or need to troubleshoot:

```bash
# Install system dependencies (example for Ubuntu/Debian)
sudo apt update
sudo apt install -y python3 python3-pip python3-venv python3-dev \
    build-essential libssl-dev libffi-dev

# Create virtual environment
python3 -m venv iac-env

# Activate virtual environment
source iac-env/bin/activate

# Install requirements
pip install -r requirements.txt
```

## Distribution-Specific Details

### Arch Linux

**Package Manager**: `pacman`

**System Packages Installed**:
```bash
sudo pacman -S --needed python python-pip python-virtualenv \
    base-devel openssl libffi git
```

**Python Detection**: Uses `python` command (Arch Linux default)

### RHEL-based Systems (CentOS, RHEL, Rocky, AlmaLinux, Fedora)

**Package Manager**: `dnf` (preferred) or `yum` (fallback)

**System Packages Installed**:
```bash
sudo dnf install -y python3 python3-pip python3-venv python3-devel \
    gcc openssl-devel libffi-devel git
```

**Python Detection**: Uses `python3` command

### Debian-based Systems (Ubuntu, Debian, Linux Mint)

**Package Manager**: `apt`

**System Packages Installed**:
```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv python3-dev \
    build-essential libssl-dev libffi-dev git
```

**Python Detection**: Uses `python3` command

## Requirements Files

The repository includes multiple requirements files for different use cases:

### requirements.txt
Core IaC tools and dependencies:
- Ansible and Ansible Core
- Cloud provider SDKs (AWS, Azure, GCP)
- VMware vSphere and Proxmox libraries
- Security and cryptography tools
- Configuration management utilities

### requirements-dev.txt
Development tools and testing frameworks:
- Testing: pytest, pytest-cov, tox
- Code quality: black, isort, flake8, pylint, mypy
- Security: bandit, safety
- Documentation: sphinx, mkdocs
- Development: pre-commit, jupyter

### requirements-tools.txt
Specialized IaC tools:
- Terraform utilities: terraform-docs, tflint, terragrunt
- Infrastructure testing: testinfra, inspec
- Security scanning: terrascan, tfsec, checkov
- Monitoring and observability tools
- Workflow and pipeline tools

## Environment Management

### Virtual Environment Naming

The setup script creates virtual environments with descriptive names:
- Format: `iac-{hostname}-{timestamp}`
- Example: `iac-server01-20240829_082100`

### Activation and Deactivation

```bash
# Activate the environment
source iac-env/bin/activate

# Verify activation (prompt should show environment name)
which python
python --version

# Deactivate when done
deactivate
```

### Environment Variables

The system supports loading environment variables from Ansible Vault:

```bash
# Load vault environment variables
source scripts/load-vault-env.sh

# Verify variables are loaded
echo $TF_VAR_vsphere_user
```

## Python Version Management

### Automatic Detection

The setup script automatically detects and uses the latest available Python version:

1. Checks for Python 3.12, 3.11, 3.10, 3.9 (in order)
2. Uses the highest version found
3. Validates the version meets minimum requirements (≥3.9)

### Manual Version Selection

If you need to use a specific Python version:

```bash
# Create environment with specific Python version
python3.11 -m venv iac-env-py311

# Activate and install requirements
source iac-env-py311/bin/activate
pip install -r requirements.txt
```

## Troubleshooting

### Common Issues

#### 1. Permission Denied Errors

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Or fix all at once
find scripts/ -name "*.sh" -exec chmod +x {} \;
```

#### 2. Package Installation Failures

```bash
# Update package manager cache
# Debian/Ubuntu:
sudo apt update

# RHEL/CentOS/Fedora:
sudo dnf update

# Arch Linux:
sudo pacman -Sy
```

#### 3. Python Version Not Found

```bash
# Install additional Python versions
# Ubuntu/Debian:
sudo apt install python3.11 python3.11-venv python3.11-dev

# Fedora:
sudo dnf install python3.11 python3.11-devel

# Arch Linux:
sudo pacman -S python311
```

#### 4. Virtual Environment Creation Fails

```bash
# Install venv module
# Ubuntu/Debian:
sudo apt install python3-venv

# RHEL/CentOS/Fedora:
sudo dnf install python3-venv

# Or use virtualenv as alternative
pip install --user virtualenv
virtualenv iac-env
```

### Distribution Detection Issues

If the script fails to detect your distribution:

```bash
# Check distribution information
cat /etc/os-release
lsb_release -a 2>/dev/null || echo "lsb_release not available"

# Check available package managers
which apt && echo "apt available"
which dnf && echo "dnf available"
which yum && echo "yum available"
which pacman && echo "pacman available"
```

### Debugging the Setup Script

Enable debug mode for detailed output:

```bash
# Run with debug output
bash -x scripts/setup-python-env.sh

# Or set debug flag in script
export DEBUG=1
./scripts/setup-python-env.sh
```

## Advanced Configuration

### Custom Virtual Environment Location

```bash
# Set custom location
export VENV_DIR="/path/to/custom/location"
./scripts/setup-python-env.sh
```

### Skip System Package Installation

```bash
# Skip system packages (if already installed)
export SKIP_SYSTEM_PACKAGES=1
./scripts/setup-python-env.sh
```

### Custom Requirements Files

```bash
# Install only specific requirements
pip install -r requirements-dev.txt  # Development only
pip install -r requirements-tools.txt  # Tools only

# Install all requirements
make setup-all
```

## Integration with Development Tools

### VS Code Integration

Add to your VS Code settings.json:

```json
{
    "python.defaultInterpreterPath": "./iac-env/bin/python",
    "python.terminal.activateEnvironment": true
}
```

### Pre-commit Hooks

```bash
# Install pre-commit hooks
pre-commit install

# Run hooks manually
pre-commit run --all-files
```

### Makefile Integration

The repository includes comprehensive Makefile targets:

```bash
# Environment setup
make setup          # Basic setup
make setup-dev      # Development setup
make setup-tools    # Tools setup
make setup-all      # Complete setup

# Code quality
make lint           # Run linting
make format         # Format code
make test           # Run tests
make security       # Security scans

# Cleanup
make clean          # Clean Python cache
make clean-terraform # Clean Terraform files
```

## Best Practices

### 1. Always Use Virtual Environments

Never install packages globally. Always use virtual environments to avoid conflicts.

### 2. Pin Dependencies

Use specific version numbers in requirements files to ensure reproducible builds.

### 3. Regular Updates

Regularly update dependencies:

```bash
make update-deps
```

### 4. Security Scanning

Regularly scan for security vulnerabilities:

```bash
make security
```

### 5. Environment Isolation

Use separate environments for different projects or purposes:

```bash
# Development environment
python -m venv iac-dev
source iac-dev/bin/activate
pip install -r requirements-dev.txt

# Production environment
python -m venv iac-prod
source iac-prod/bin/activate
pip install -r requirements.txt
```

## Performance Optimization

### 1. Use pip-tools for Dependency Management

```bash
pip install pip-tools

# Generate locked requirements
pip-compile requirements.in
pip-compile requirements-dev.in
```

### 2. Use pip Cache

```bash
# Enable pip cache (usually enabled by default)
pip config set global.cache-dir ~/.cache/pip
```

### 3. Parallel Installation

```bash
# Install packages in parallel
pip install -r requirements.txt --use-pep517 --no-build-isolation
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: [3.9, 3.10, 3.11, 3.12]
    
    steps:
    - uses: actions/checkout@v4
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements-dev.txt
    
    - name: Run tests
      run: make ci-check
```

## Support and Contributing

### Getting Help

1. Check this documentation first
2. Review the troubleshooting section
3. Check existing GitHub issues
4. Create a new issue with detailed information

### Contributing

1. Fork the repository
2. Create a feature branch
3. Set up development environment: `make dev-setup`
4. Make changes and test: `make ci-check`
5. Submit a pull request

### Reporting Issues

When reporting issues, include:

- Operating system and version
- Python version
- Error messages and stack traces
- Steps to reproduce
- Output of `make status`

## References

- [Python Virtual Environments Guide](https://docs.python.org/3/tutorial/venv.html)
- [pip User Guide](https://pip.pypa.io/en/stable/user_guide/)
- [Ansible Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/index.html)
- [Terraform Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
