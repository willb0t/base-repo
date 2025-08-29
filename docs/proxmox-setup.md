# Proxmox Setup Guide

This guide provides detailed instructions for setting up GitLab CE on Proxmox VE using this Infrastructure-as-Code repository.

## Prerequisites

### Software Requirements
- **Terraform** >= 1.0
- **Ansible** >= 2.9
- **Git** for cloning the repository

### Proxmox Requirements
- Proxmox VE 7.0 or later
- Proxmox API token with appropriate permissions
- Ubuntu 22.04+ cloud-init template
- Network connectivity between your workstation and Proxmox

### Proxmox Permissions Required
Your Proxmox user needs the following permissions:
- **VM.Allocate**: Create/modify VMs
- **VM.Config.Disk**: Manage VM disks
- **VM.Config.Memory**: Manage VM memory
- **VM.Config.Network**: Manage VM network
- **VM.Config.Options**: Manage VM options
- **VM.Monitor**: Monitor VMs
- **VM.PowerMgmt**: Power management
- **Datastore.AllocateSpace**: Allocate storage space

## Step 1: Create API Token

1. Log into Proxmox web interface
2. Navigate to **Datacenter** > **Permissions** > **API Tokens**
3. Click **Add** to create a new token:
   - **User**: Select or create a user (e.g., `terraform@pve`)
   - **Token ID**: `terraform`
   - **Privilege Separation**: Uncheck (for simplicity)
4. Save the generated token securely

## Step 2: Create Ubuntu Cloud-Init Template

### Download and Import Cloud Image

1. SSH to your Proxmox node and download Ubuntu cloud image:
   ```bash
   cd /tmp
   wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
   ```

2. Create a new VM for the template:
   ```bash
   qm create 9000 --name ubuntu-22.04-cloudinit --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
   ```

3. Import the cloud image as a disk:
   ```bash
   qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
   ```

4. Attach the disk to the VM:
   ```bash
   qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
   ```

5. Add cloud-init drive:
   ```bash
   qm set 9000 --ide2 local-lvm:cloudinit
   ```

6. Configure boot order:
   ```bash
   qm set 9000 --boot c --bootdisk scsi0
   ```

7. Add serial console:
   ```bash
   qm set 9000 --serial0 socket --vga serial0
   ```

8. Enable QEMU guest agent:
   ```bash
   qm set 9000 --agent enabled=1
   ```

9. Convert to template:
   ```bash
   qm template 9000
   ```

### Alternative: Use Proxmox Web Interface

1. Download the cloud image to your local machine
2. In Proxmox web interface:
   - Create new VM (ID: 9000, Name: ubuntu-22.04-cloudinit)
   - Don't add any disks during creation
   - Go to **Hardware** tab
   - Add **Hard Disk** > **Import disk** > Select downloaded image
   - Add **CloudInit Drive**
   - Set boot order to the imported disk
   - Convert to template

## Step 3: Configure Environment Variables

1. Copy the example configuration:
   ```bash
   cp terraform/environments/proxmox.tfvars.example terraform/environments/proxmox.tfvars
   ```

2. Edit `terraform/environments/proxmox.tfvars` with your environment details:

### Required Configuration
```hcl
# Platform Selection
platform = "proxmox"

# VM Configuration
vm_name      = "gitlab-ce"
vm_cpu       = 4
vm_memory    = 8192
vm_disk_size = 50
vm_network   = "vmbr0"  # Your Proxmox bridge name
vm_domain    = "yourdomain.com"

# Proxmox Configuration
proxmox_api_url      = "https://proxmox.yourdomain.com:8006/api2/json"
proxmox_api_token_id = "terraform@pve!terraform"
proxmox_api_token    = "your-api-token-secret"
proxmox_node         = "proxmox-node1"  # Your Proxmox node name
proxmox_template     = "ubuntu-22.04-cloudinit"

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

## Step 4: Deploy Infrastructure

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Plan the deployment:
   ```bash
   terraform plan -var-file="terraform/environments/proxmox.tfvars"
   ```

3. Deploy the infrastructure:
   ```bash
   terraform apply -var-file="terraform/environments/proxmox.tfvars"
   ```

4. Note the outputs:
   - VM IP address
   - SSH connection command
   - GitLab URL

## Step 5: Configure GitLab with Ansible

1. Run the GitLab setup playbook:
   ```bash
   ansible-playbook -i ansible/inventories/hosts ansible/playbooks/gitlab-setup.yml
   ```

2. Wait for the installation to complete (this may take 10-15 minutes)

## Step 6: Access GitLab

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

#### API Authentication Failed
- Verify API token is correct
- Check token permissions
- Ensure API token is not expired
- Verify Proxmox URL is accessible

#### Template Not Found
- Verify template name matches exactly
- Check template exists on the specified node
- Ensure template has cloud-init drive

#### VM Creation Failed
- Check storage space availability
- Verify network bridge exists
- Check node resources (CPU, memory)

#### SSH Connection Failed
- Verify SSH key permissions (600 for private key)
- Check cloud-init logs: `/var/log/cloud-init.log`
- Ensure VM has network connectivity
- Check QEMU guest agent status

#### GitLab Not Accessible
- Check firewall settings
- Verify GitLab services: `sudo gitlab-ctl status`
- Check GitLab logs: `sudo gitlab-ctl tail`

### Useful Commands

#### Proxmox Commands
```bash
# List VMs
qm list

# Show VM configuration
qm config <vmid>

# Start/stop VM
qm start <vmid>
qm stop <vmid>

# Check VM status
qm status <vmid>

# View VM console
qm monitor <vmid>

# Clone template
qm clone <template-id> <new-vmid> --name <new-name>
```

#### GitLab Commands
```bash
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
terraform destroy -var-file="terraform/environments/proxmox.tfvars"
```

## Advanced Configuration

### Storage Options
You can specify different storage for VM disks:
```hcl
# In proxmox module variables
proxmox_storage = "local-lvm"  # or "local-zfs", "ceph", etc.
```

### Network Options
For VLAN configuration:
```hcl
# In proxmox.tfvars
vm_network = "vmbr0"
# Add VLAN tag if needed (in module variables)
vlan_tag = 100
```

### Performance Tuning
For better performance:
```hcl
# Increase VM resources
vm_cpu       = 8
vm_memory    = 16384
vm_disk_size = 100
```

## Security Considerations

1. **API Tokens**: Use dedicated tokens with minimal required permissions
2. **Network Security**: Use VLANs and firewalls to isolate GitLab
3. **SSH Keys**: Use strong SSH keys and protect private keys
4. **SSL**: Use proper SSL certificates in production
5. **Backups**: Implement regular VM and GitLab backups
6. **Updates**: Keep Proxmox, VMs, and GitLab updated

## Backup Strategy

### VM Backups
Configure automatic VM backups in Proxmox:
1. Go to **Datacenter** > **Backup**
2. Create backup job for GitLab VM
3. Schedule regular backups

### GitLab Backups
GitLab backups are automatically configured via Ansible:
- Daily backups at 2 AM
- 7-day retention policy
- Stored in `/var/opt/gitlab/backups`

## Next Steps

1. Configure GitLab settings (email, CI/CD, etc.)
2. Set up SSL certificates
3. Configure backup strategies
4. Set up monitoring and alerting
5. Create user accounts and projects
6. Configure GitLab runners for CI/CD
