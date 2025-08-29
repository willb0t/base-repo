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

1. **Terraform** >= 1.0
2. **Ansible** >= 2.9
3. **Platform Access**:
   - For vSphere: vCenter credentials and Ubuntu 22.04+ template
   - For Proxmox: Proxmox VE credentials and Ubuntu 22.04+ cloud image

### Basic Usage

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd gitlab-iac-terraform
   ```

2. Copy and customize environment variables:
   ```bash
   # For VMware vSphere
   cp terraform/environments/vsphere.tfvars.example terraform/environments/vsphere.tfvars
   
   # For Proxmox
   cp terraform/environments/proxmox.tfvars.example terraform/environments/proxmox.tfvars
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Deploy to your chosen platform:
   ```bash
   # Deploy to VMware vSphere
   terraform apply -var="platform=vsphere" -var-file="terraform/environments/vsphere.tfvars"
   
   # Deploy to Proxmox
   terraform apply -var="platform=proxmox" -var-file="terraform/environments/proxmox.tfvars"
   ```

5. Configure GitLab with Ansible:
   ```bash
   # Run the GitLab installation playbook
   ansible-playbook -i ansible/inventories/hosts ansible/playbooks/gitlab-setup.yml
   ```

## Repository Structure

```
gitlab-iac-terraform/
├── README.md                           # This file
├── main.tf                            # Main Terraform configuration
├── variables.tf                       # Global variables
├── outputs.tf                         # Terraform outputs
├── terraform/
│   ├── modules/
│   │   ├── vsphere/                   # VMware vSphere module
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── proxmox/                   # Proxmox module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── environments/
│       ├── vsphere.tfvars.example     # vSphere configuration example
│       └── proxmox.tfvars.example     # Proxmox configuration example
├── ansible/
│   ├── playbooks/
│   │   ├── gitlab-setup.yml           # Main GitLab setup playbook
│   │   └── ldap-integration.yml       # Optional LDAP integration
│   ├── roles/
│   │   ├── common/                    # Base system configuration
│   │   ├── gitlab-ce/                 # GitLab CE installation
│   │   └── ldap-integration/          # LDAP configuration
│   ├── inventories/
│   │   └── hosts                      # Dynamic inventory template
│   └── ansible.cfg                    # Ansible configuration
├── docs/
│   ├── vsphere-setup.md              # vSphere-specific setup guide
│   ├── proxmox-setup.md              # Proxmox-specific setup guide
│   ├── template-creation.md          # Cloud-init template creation
│   └── troubleshooting.md            # Common issues and solutions
└── scripts/
    ├── generate-ssh-keys.sh          # SSH key generation utility
    └── setup-environment.sh          # Environment setup script
```

## Platform-Specific Documentation

- [VMware vSphere Setup Guide](docs/vsphere-setup.md)
- [Proxmox Setup Guide](docs/proxmox-setup.md)
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
