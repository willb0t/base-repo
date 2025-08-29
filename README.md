# GitLab CE Infrastructure-as-Code

This repository provides a complete Infrastructure-as-Code (IaC) solution for provisioning Ubuntu virtual machines with GitLab Community Edition on either VMware vSphere or Proxmox using Terraform and Ansible.

## Features

- **Multi-Platform Support**: Deploy to either VMware vSphere or Proxmox
- **Modular Design**: Clean separation between platform-specific and common configurations
- **Cloud-Init Ready**: Uses cloud-init templates for fast, reliable deployments
- **GitLab CE Installation**: Native GitLab Community Edition installation (no containers)
- **LDAP Integration**: Optional LDAP authentication (Univention UCS example included)
- **Security Best Practices**: No secrets in code, SSH key management, secure defaults
- **Comprehensive Documentation**: Step-by-step guides for both platforms

## Quick Start

### Prerequisites

#### System Requirements

1. **Operating System**: Linux (Arch Linux, RHEL-based, or Debian-based)
2. **Python**: 3.9+ (automatically detected and installed)
3. **Platform Access**:
   - For vSphere: vCenter credentials and Ubuntu 22.04+ template
   - For Proxmox: Proxmox VE credentials and Ubuntu 22.04+ cloud image

#### Automated Environment Setup

The repository includes an intelligent setup system that automatically detects your Linux distribution and installs all required tools:

```bash
# Quick setup (recommended)
make dev-setup

# Or step-by-step setup
chmod +x scripts/setup-python-env.sh
./scripts/setup-python-env.sh
```

**Supported Systems:**
- **100+ Linux Distributions**: Comprehensive support from DistroWatch database
- **BSD Systems**: FreeBSD, OpenBSD, NetBSD, DragonFlyBSD, and derivatives
- **All Major Families**: Arch, Debian/Ubuntu, RHEL/Fedora, SUSE, Gentoo, Slackware, and Independent distributions

**Distribution Families Supported:**
- **BSD Family** (9 systems): FreeBSD, OpenBSD, NetBSD, DragonFlyBSD, GhostBSD, TrueNAS, etc.
- **Arch Linux Family** (18+ distributions): Arch, Manjaro, EndeavourOS, Garuda, CachyOS, ArcoLinux, Artix, etc.
- **RHEL/Red Hat Family** (10+ distributions): RHEL, CentOS, AlmaLinux, Rocky, Fedora, Nobara, etc.
- **Debian Family** (40+ distributions): Debian, Ubuntu (all flavors), Mint, Pop!_OS, Kali, Parrot, etc.
- **SUSE Family**: openSUSE (Leap, Tumbleweed), SLES
- **Independent**: NixOS, Void Linux, Alpine Linux, Solus, and many more

The universal setup script will:
1. Detect your Linux distribution or BSD system automatically using comprehensive database
2. Install appropriate system dependencies using the correct package manager
3. Create a Python virtual environment with the latest available Python version
4. Install all IaC tools (Terraform utilities, Ansible, cloud SDKs)
5. Set up development tools (linting, testing, security scanning)

#### Manual Prerequisites (if not using automated setup)

1. **Terraform** >= 1.0
2. **Ansible** >= 2.9
3. **Python** >= 3.9 with pip and venv
4. **Git** for version control

### Secure Setup (Recommended)

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd gitlab-iac-terraform
   ```

2. Set up secure credential storage:
   ```bash
   # Create encrypted vault for credentials
   ./scripts/manage-vault.sh create
   
   # Edit vault with your actual credentials
   ./scripts/manage-vault.sh edit
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Deploy to your chosen platform:
   ```bash
   # Load credentials and deploy to vSphere
   source <(./scripts/load-vault-env.sh load vsphere)
   terraform apply -var="platform=vsphere"
   
   # Or load credentials and deploy to Proxmox
   source <(./scripts/load-vault-env.sh load proxmox)
   terraform apply -var="platform=proxmox"
   ```

5. Configure GitLab with Ansible:
   ```bash
   # Run the GitLab installation playbook (vault automatically used)
   ansible-playbook -i ansible/inventories/hosts ansible/playbooks/gitlab-setup.yml
   ```

### Alternative: Plain Text Setup (Not Recommended for Production)

1. Copy and customize environment variables:
   ```bash
   # For VMware vSphere
   cp terraform/environments/vsphere.tfvars.example terraform/environments/vsphere.tfvars
   
   # For Proxmox
   cp terraform/environments/proxmox.tfvars.example terraform/environments/proxmox.tfvars
   ```

2. Deploy with variable files:
   ```bash
   # Deploy to VMware vSphere
   terraform apply -var="platform=vsphere" -var-file="terraform/environments/vsphere.tfvars"
   
   # Deploy to Proxmox
   terraform apply -var="platform=proxmox" -var-file="terraform/environments/proxmox.tfvars"
   ```

## Repository Structure

```
gitlab-iac-terraform/
├── README.md                           # This file
├── main.tf                            # Main Terraform configuration
├── variables.tf                       # Global variables
├── outputs.tf                         # Terraform outputs
├── .gitignore                         # Git ignore rules (includes vault security)
├── terraform/
│   ├── modules/
│   │   ├── vsphere/                   # VMware vSphere module
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── cloud-init-user-data.yml
│   │   │   └── cloud-init-meta-data.yml
│   │   └── proxmox/                   # Proxmox module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── cloud-init-user-data.yml
│   └── environments/
│       ├── vsphere.tfvars.example     # vSphere configuration example
│       └── proxmox.tfvars.example     # Proxmox configuration example
├── ansible/
│   ├── group_vars/
│   │   └── all/
│   │       └── vault.yml              # Encrypted credentials (created by script)
│   ├── playbooks/
│   │   ├── gitlab-setup.yml           # Main GitLab setup playbook
│   │   └── ldap-integration.yml       # Optional LDAP integration
│   ├── roles/
│   │   ├── common/                    # Base system configuration
│   │   ├── gitlab-ce/                 # GitLab CE installation
│   │   └── ldap-integration/          # LDAP configuration
│   ├── inventories/
│   │   └── hosts.tpl                  # Dynamic inventory template
│   └── ansible.cfg                    # Ansible configuration
├── docs/
│   ├── vsphere-setup.md              # vSphere-specific setup guide
│   ├── proxmox-setup.md              # Proxmox-specific setup guide
│   ├── secure-credentials.md         # Secure credential management guide
│   ├── template-creation.md          # Cloud-init template creation
│   └── troubleshooting.md            # Common issues and solutions
└── scripts/
    ├── generate-ssh-keys.sh          # SSH key generation utility
    ├── manage-vault.sh               # Ansible Vault management script
    ├── load-vault-env.sh             # Environment variable loader
    └── setup-environment.sh          # Environment setup script
```

## Development Environment

### Python Environment Management

This repository includes a sophisticated Python environment management system with multi-distribution support. For detailed information, see the [Python Environment Setup Guide](docs/python-environment.md).

#### Quick Environment Setup Options

```bash
# Complete development setup (recommended for contributors)
make dev-setup

# Basic setup with core IaC tools only
make setup

# Setup with development tools
make setup-dev

# Setup with specialized IaC tools
make setup-tools

# Setup everything (core + dev + tools)
make setup-all
```

#### Environment Management Commands

```bash
# View all available commands
make help

# Check current environment status
make status

# Run code quality checks
make lint

# Run security scans
make security

# Clean up temporary files
make clean

# Validate Terraform configuration
make validate
```

#### Requirements Files

The repository includes multiple requirements files for different use cases:

- **`requirements.txt`**: Core IaC tools (Ansible, cloud SDKs, Terraform utilities)
- **`requirements-dev.txt`**: Development tools (testing, linting, documentation)
- **`requirements-tools.txt`**: Specialized IaC tools (security scanning, infrastructure testing)

## Platform-Specific Documentation

- [Python Environment Setup Guide](docs/python-environment.md)
- [VMware vSphere Setup Guide](docs/vsphere-setup.md)
- [Proxmox Setup Guide](docs/proxmox-setup.md)
- [Secure Credential Management](docs/secure-credentials.md)
- [Cloud-Init Template Creation](docs/template-creation.md)

## Configuration

### VM Specifications (Customizable)

- **CPU**: 4 cores (default)
- **Memory**: 8GB (default)
- **Disk**: 50GB (default)
- **OS**: Ubuntu 22.04+ LTS
- **Network**: DHCP (with static IP option)

### GitLab Configuration

- **Version**: Latest GitLab CE
- **Installation**: Native (non-containerized)
- **SSL**: Self-signed certificates (with Let's Encrypt option)
- **Authentication**: Local users + optional LDAP integration

## Security Considerations

- All secrets are managed via variables (never hardcoded)
- SSH key-based authentication
- Firewall configuration included
- Regular security updates via Ansible
- GitLab security best practices applied

## Troubleshooting

See [troubleshooting.md](docs/troubleshooting.md) for common issues and solutions.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both platforms if possible
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting guide
2. Review platform-specific documentation
3. Open an issue with detailed information about your environment
