# VMware vSphere Setup Guide

This guide provides detailed instructions for setting up GitLab CE on VMware vSphere using this Infrastructure-as-Code repository.

## Prerequisites

### Software Requirements
- **Terraform** >= 1.0
- **Ansible** >= 2.9
- **Git** for cloning the repository

### vSphere Requirements
- VMware vCenter Server 6.7 or later
- vSphere user account with appropriate permissions
- Ubuntu 22.04+ VM template with cloud-init support
- Network connectivity between your workstation and vCenter

### vSphere Permissions Required
Your vSphere user account needs the following permissions:
- **Datastore**: Allocate space, Browse datastore, Low level file operations
- **Network**: Assign network
- **Resource**: Assign virtual machine to resource pool
- **Virtual Machine**: All privileges (or specific privileges for VM operations)
- **vApp**: All privileges

## Step 1: Create Ubuntu Cloud-Init Template

### Option A: Download Pre-built Cloud Image
1. Download Ubuntu 22.04 cloud image:
   ```bash
   wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.ova
   ```

2. Import the OVA into vSphere:
   - Open vSphere Client
   - Right-click on your datacenter or cluster
   - Select "Deploy OVF Template"
   - Upload the downloaded OVA file
   - Follow the wizard to complete deployment

3. Convert to template:
   - Right-click the deployed VM
   - Select "Template" > "Convert to Template"
   - Name it `ubuntu-22.04-template`

### Option B: Create Custom Template
1. Create a new VM with Ubuntu 22.04 Server
2. Install cloud-init and VMware Tools:
   ```bash
   sudo apt update
   sudo apt install -y cloud-init open-vm-tools
   ```
3. Configure cloud-init datasource for VMware:
   ```bash
   sudo echo 'datasource_list: [ VMware, OVF, None ]' > /etc/cloud/cloud.cfg.d/90_dpkg.cfg
   ```
4. Clean the VM and convert to template

## Step 2: Configure Environment Variables

1. Copy the example configuration:
   ```bash
   cp terraform/environments/vsphere.tfvars.example terraform/environments/vsphere.tfvars
   ```

2. Edit `terraform/environments/vsphere.tfvars` with your environment details:

### Required Configuration
```hcl
# Platform Selection
platform = "vsphere"

# VM Configuration
vm_name      = "gitlab-ce"
vm_cpu       = 4
vm_memory    = 8192
vm_disk_size = 50
vm_network   = "VM Network"  # Your vSphere network name
vm_domain    = "yourdomain.com"

# VMware vSphere Configuration
vsphere_server     = "vcenter.yourdomain.com"
vsphere_user       = "administrator@vsphere.local"
vsphere_password   = "your-secure-password"
vsphere_datacenter = "Your-Datacenter"
vsphere_cluster    = "Your-Cluster"
vsphere_datastore  = "your-datastore"
vsphere_template   = "ubuntu-22.04-template"

# GitLab Configuration
gitlab_external_url = "https://gitlab.yourdomain.com"
```

### Network Configuration Options

#### DHCP (Recommended for testing)
```hcl
use_static_ip = false
dns_servers   = ["8.8.8.8", "8.8.4.4"]
```

#### Static IP
```hcl
use_static_ip = true
static_ip     = "192.168.1.100"
gateway       = "192.168.1.1"
dns_servers   = ["192.168.1.10", "8.8.8.8"]
```

### SSH Configuration Options

#### Generate New SSH Key (Recommended)
```hcl
ssh_public_key       = ""  # Leave empty
ssh_private_key_file = "~/.ssh/id_rsa"
ssh_username         = "ubuntu"
```

#### Use Existing SSH Key
```hcl
ssh_public_key       = "ssh-rsa AAAAB3NzaC1yc2E... your-key"
ssh_private_key_file = "/path/to/your/private/key"
ssh_username         = "ubuntu"
```

## Step 3: Deploy Infrastructure

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Plan the deployment:
   ```bash
   terraform plan -var-file="terraform/environments/vsphere.tfvars"
   ```

3. Deploy the infrastructure:
   ```bash
   terraform apply -var-file="terraform/environments/vsphere.tfvars"
   ```

4. Note the outputs:
   - VM IP address
   - SSH connection command
   - GitLab URL

## Step 4: Configure GitLab with Ansible

1. Run the GitLab setup playbook:
   ```bash
   ansible-playbook -i ansible/inventories/hosts ansible/playbooks/gitlab-setup.yml
   ```

2. Wait for the installation to complete (this may take 10-15 minutes)

## Step 5: Access GitLab

1. Open your browser and navigate to the GitLab URL
2. Login as `root`
3. Get the initial password:
   ```bash
   ssh -i /path/to/ssh/key ubuntu@<vm-ip>
   sudo cat /etc/gitlab/initial_root_password
   ```
4. Change the root password after first login

## LDAP Integration (Optional)

To enable LDAP authentication, update your tfvars file:

```hcl
enable_ldap    = true
ldap_host      = "ldap.yourdomain.com"
ldap_port      = 389
ldap_bind_dn   = "cn=admin,dc=yourdomain,dc=com"
ldap_password  = "ldap-password"
ldap_base      = "dc=yourdomain,dc=com"
ldap_user_filter = ""
```

Then run the LDAP integration playbook:
```bash
ansible-playbook -i ansible/inventories/hosts ansible/playbooks/ldap-integration.yml
```

## Troubleshooting

### Common Issues

#### Template Not Found
- Verify the template name matches exactly
- Ensure the template is in the correct datacenter
- Check template permissions

#### Network Issues
- Verify network name is correct
- Check VLAN configuration
- Ensure DNS servers are reachable

#### SSH Connection Failed
- Verify SSH key permissions (600 for private key)
- Check cloud-init logs: `/var/log/cloud-init.log`
- Ensure VM has network connectivity

#### GitLab Not Accessible
- Check firewall settings
- Verify GitLab services: `sudo gitlab-ctl status`
- Check GitLab logs: `sudo gitlab-ctl tail`

### Useful Commands

```bash
# Check VM status in vSphere
# Use vSphere Client or PowerCLI

# SSH to the VM
ssh -i /path/to/ssh/key ubuntu@<vm-ip>

# Check GitLab status
sudo gitlab-ctl status

# Reconfigure GitLab
sudo gitlab-ctl reconfigure

# View GitLab logs
sudo gitlab-ctl tail

# Test LDAP connection (if enabled)
sudo gitlab-rake gitlab:ldap:check
```

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy -var-file="terraform/environments/vsphere.tfvars"
```

## Security Considerations

1. **Credentials**: Never commit passwords to version control
2. **SSH Keys**: Use strong SSH keys and protect private keys
3. **Network**: Consider using private networks and VPNs
4. **SSL**: Use proper SSL certificates in production
5. **Backups**: Implement regular backup strategies
6. **Updates**: Keep GitLab and system packages updated

## Next Steps

1. Configure GitLab settings (email, CI/CD, etc.)
2. Set up SSL certificates
3. Configure backup strategies
4. Set up monitoring and alerting
5. Create user accounts and projects
