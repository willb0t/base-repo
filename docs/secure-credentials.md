# Secure Credential Management with Ansible Vault

This guide explains how to securely manage credentials for your GitLab Infrastructure-as-Code deployment using Ansible Vault.

## Overview

Instead of storing sensitive credentials in plain text files, this solution uses Ansible Vault to encrypt credentials and provides scripts to seamlessly integrate them with Terraform and Ansible.

## Security Benefits

- **Encryption**: All sensitive data is encrypted using AES256
- **Version Control Safe**: Encrypted files can be safely committed to git
- **Access Control**: Only users with the vault password can decrypt credentials
- **Audit Trail**: Changes to encrypted files are tracked in git
- **No Plain Text**: Credentials never exist in plain text in your repository

## Quick Start

### 1. Create Vault File

```bash
# Create a new encrypted vault file with template
./scripts/manage-vault.sh create
```

This will:
- Generate a secure vault password
- Create the encrypted vault file with template
- Set up proper directory structure
- Update .gitignore for security

### 2. Edit Credentials

```bash
# Edit the vault file to add your actual credentials
./scripts/manage-vault.sh edit
```

### 3. Load Credentials for Terraform

```bash
# Load vSphere credentials
source <(./scripts/load-vault-env.sh load vsphere)

# Or load Proxmox credentials
source <(./scripts/load-vault-env.sh load proxmox)

# Then run Terraform
terraform apply -var="platform=vsphere"
```

### 4. Run Ansible with Vault

```bash
# Ansible automatically uses the vault file
ansible-playbook -i ansible/inventories/hosts ansible/playbooks/gitlab-setup.yml --vault-password-file=.vault_password
```

## Detailed Usage

### Vault Management Commands

```bash
# Create new vault
./scripts/manage-vault.sh create

# Edit vault contents
./scripts/manage-vault.sh edit

# View vault contents (read-only)
./scripts/manage-vault.sh view

# Validate vault file
./scripts/manage-vault.sh validate

# Backup vault file
./scripts/manage-vault.sh backup

# Change vault password
./scripts/manage-vault.sh change-password
```

### Environment Variable Management

```bash
# Load all credentials
source <(./scripts/load-vault-env.sh load)

# Load platform-specific credentials
source <(./scripts/load-vault-env.sh load vsphere)
source <(./scripts/load-vault-env.sh load proxmox)

# Show current environment variables
./scripts/load-vault-env.sh show

# Validate loaded variables
./scripts/load-vault-env.sh validate vsphere

# Test connection to platform
./scripts/load-vault-env.sh test vsphere

# Clear environment variables
source <(./scripts/load-vault-env.sh clear)
```

## Vault File Structure

The vault file contains encrypted credentials organized by platform:

```yaml
---
# VMware vSphere Credentials
vault_vsphere_server: "vcenter.example.com"
vault_vsphere_user: "administrator@vsphere.local"
vault_vsphere_password: "your-secure-password"

# Proxmox Credentials
vault_proxmox_api_url: "https://proxmox.example.com:8006/api2/json"
vault_proxmox_api_token_id: "terraform@pve!terraform"
vault_proxmox_api_token: "your-secure-token"

# LDAP Credentials
vault_ldap_bind_dn: "cn=admin,dc=example,dc=com"
vault_ldap_password: "your-ldap-password"

# GitLab Configuration
vault_gitlab_initial_root_password: "your-gitlab-password"

# SSH Keys (if using existing keys)
vault_ssh_public_key: "ssh-rsa AAAAB3NzaC1yc2E..."
vault_ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
```

## Integration with Terraform

### Environment Variables

The vault system automatically converts vault variables to Terraform environment variables:

- `vault_vsphere_password` → `TF_VAR_vsphere_password`
- `vault_proxmox_api_token` → `TF_VAR_proxmox_api_token`
- etc.

### Usage Pattern

```bash
# 1. Load credentials
source <(./scripts/load-vault-env.sh load vsphere)

# 2. Verify credentials are loaded
./scripts/load-vault-env.sh validate vsphere

# 3. Test connection (optional)
./scripts/load-vault-env.sh test vsphere

# 4. Run Terraform
terraform plan -var="platform=vsphere"
terraform apply -var="platform=vsphere"
```

## Integration with Ansible

### Automatic Integration

Ansible automatically uses vault variables when the vault password file exists:

```bash
ansible-playbook -i ansible/inventories/hosts ansible/playbooks/gitlab-setup.yml --vault-password-file=.vault_password
```

### Manual Integration

You can also reference vault variables in Ansible playbooks:

```yaml
- name: Configure GitLab with vault credentials
  set_fact:
    gitlab_root_password: "{{ vault_gitlab_initial_root_password }}"
```

## Security Best Practices

### 1. Vault Password Management

- **Never commit** the `.vault_password` file to git
- **Store vault password securely** (password manager, secure notes)
- **Share vault password** through secure channels (not email/chat)
- **Rotate vault password** regularly using `change-password` command

### 2. Access Control

```bash
# Set restrictive permissions on vault password file
chmod 600 .vault_password

# Verify .gitignore excludes sensitive files
git status --ignored
```

### 3. Backup Strategy

```bash
# Regular backups
./scripts/manage-vault.sh backup

# Backup before major changes
./scripts/manage-vault.sh backup
./scripts/manage-vault.sh edit
```

### 4. Team Collaboration

1. **Initial Setup**: One team member creates vault and shares password securely
2. **Adding Credentials**: Team members can edit vault with shared password
3. **Password Rotation**: Use `change-password` and share new password
4. **Access Revocation**: Change vault password when team members leave

## CI/CD Integration

### Environment Variables

For CI/CD systems, store the vault password as a secure environment variable:

```bash
# In CI/CD system, set:
VAULT_PASSWORD="your-vault-password"

# In CI/CD script:
echo "$VAULT_PASSWORD" > .vault_password
chmod 600 .vault_password
source <(./scripts/load-vault-env.sh load vsphere)
terraform apply -var="platform=vsphere"
```

### GitLab CI Example

```yaml
variables:
  VAULT_PASSWORD: $VAULT_PASSWORD_SECRET

before_script:
  - echo "$VAULT_PASSWORD" > .vault_password
  - chmod 600 .vault_password

deploy:
  script:
    - source <(./scripts/load-vault-env.sh load vsphere)
    - terraform init
    - terraform apply -auto-approve -var="platform=vsphere"
```

### GitHub Actions Example

```yaml
env:
  VAULT_PASSWORD: ${{ secrets.VAULT_PASSWORD }}

steps:
  - name: Setup vault password
    run: |
      echo "$VAULT_PASSWORD" > .vault_password
      chmod 600 .vault_password
  
  - name: Deploy infrastructure
    run: |
      source <(./scripts/load-vault-env.sh load vsphere)
      terraform apply -auto-approve -var="platform=vsphere"
```

## Troubleshooting

### Common Issues

#### Vault Password Not Found
```bash
# Error: Vault password file not found
# Solution: Create vault first
./scripts/manage-vault.sh create
```

#### Cannot Decrypt Vault
```bash
# Error: Failed to decrypt vault file
# Solution: Check vault password is correct
./scripts/manage-vault.sh validate
```

#### Environment Variables Not Set
```bash
# Check if variables are loaded
./scripts/load-vault-env.sh show

# Reload variables
source <(./scripts/load-vault-env.sh load vsphere)
```

#### Connection Test Fails
```bash
# Test platform connectivity
./scripts/load-vault-env.sh test vsphere

# Check credentials in vault
./scripts/manage-vault.sh view
```

### Debugging Commands

```bash
# Check vault file status
./scripts/manage-vault.sh validate

# View current environment variables
env | grep TF_VAR_

# Test specific platform
./scripts/load-vault-env.sh test vsphere
./scripts/load-vault-env.sh test proxmox

# Check file permissions
ls -la .vault_password
ls -la ansible/group_vars/all/vault.yml
```

## Migration from Plain Text

If you have existing plain text credentials, here's how to migrate:

### 1. Create Vault

```bash
./scripts/manage-vault.sh create
```

### 2. Edit Vault with Your Credentials

```bash
./scripts/manage-vault.sh edit
# Replace template values with your actual credentials
```

### 3. Update Your Workflow

```bash
# Old way:
terraform apply -var-file="terraform/environments/vsphere.tfvars"

# New way:
source <(./scripts/load-vault-env.sh load vsphere)
terraform apply -var="platform=vsphere"
```

### 4. Remove Plain Text Files

```bash
# Remove plain text credential files
rm terraform/environments/vsphere.tfvars
rm terraform/environments/proxmox.tfvars

# Keep only example files
git add terraform/environments/*.example
```

## Advanced Usage

### Multiple Environments

You can create separate vault files for different environments:

```bash
# Production vault
cp ansible/group_vars/all/vault.yml ansible/group_vars/all/vault-prod.yml
./scripts/manage-vault.sh edit  # Edit production credentials

# Development vault  
cp ansible/group_vars/all/vault.yml ansible/group_vars/all/vault-dev.yml
# Edit with development credentials
```

### Custom Vault Locations

```bash
# Use custom vault file
VAULT_FILE="custom-vault.yml" ./scripts/manage-vault.sh create
VAULT_FILE="custom-vault.yml" ./scripts/load-vault-env.sh load vsphere
```

### Scripted Deployment

```bash
#!/bin/bash
# deploy.sh - Automated deployment script

set -e

PLATFORM="${1:-vsphere}"

echo "Loading credentials for $PLATFORM..."
source <(./scripts/load-vault-env.sh load "$PLATFORM")

echo "Validating credentials..."
./scripts/load-vault-env.sh validate "$PLATFORM"

echo "Testing connection..."
./scripts/load-vault-env.sh test "$PLATFORM"

echo "Deploying infrastructure..."
terraform apply -auto-approve -var="platform=$PLATFORM"

echo "Configuring GitLab..."
ansible-playbook -i ansible/inventories/hosts ansible/playbooks/gitlab-setup.yml --vault-password-file=.vault_password

echo "Deployment complete!"
```

## Security Considerations

1. **Vault Password**: Treat as root password - store securely
2. **File Permissions**: Ensure restrictive permissions on sensitive files
