# Troubleshooting Guide

This guide covers common issues and solutions when deploying GitLab CE using this Infrastructure-as-Code repository.

## General Troubleshooting Steps

1. **Check Prerequisites**: Ensure all required software is installed and versions meet requirements
2. **Verify Credentials**: Double-check all authentication credentials and permissions
3. **Review Logs**: Check Terraform, Ansible, and GitLab logs for error messages
4. **Test Connectivity**: Verify network connectivity between components
5. **Check Resources**: Ensure sufficient CPU, memory, and disk space

## Terraform Issues

### Error: Failed to Initialize Provider

**Symptoms:**
```
Error: Failed to lock provider registry.terraform.io/hashicorp/vsphere
```

**Solutions:**
1. Check internet connectivity
2. Clear Terraform cache:
   ```bash
   rm -rf .terraform
   terraform init
   ```
3. Use specific provider versions in `main.tf`

### Error: Authentication Failed

**vSphere:**
```
Error: ServerFaultCode: Cannot complete login due to an incorrect user name or password
```

**Proxmox:**
```
Error: 401 Unauthorized
```

**Solutions:**
1. Verify credentials in tfvars file
2. Check user permissions
3. For Proxmox, ensure API token is not expired
4. Test credentials manually:
   ```bash
   # vSphere
   curl -k -X POST https://vcenter.example.com/rest/com/vmware/cis/session \
     -u "username:password"
   
   # Proxmox
   curl -k https://proxmox.example.com:8006/api2/json/access/ticket \
     -d "username=user@pve&password=password"
   ```

### Error: Template Not Found

**Symptoms:**
```
Error: template 'ubuntu-22.04-template' not found
```

**Solutions:**
1. Verify template name matches exactly (case-sensitive)
2. Check template exists in correct datacenter/node
3. Ensure template has proper permissions
4. For vSphere, verify template is in correct folder

### Error: Network Not Found

**Symptoms:**
```
Error: network 'VM Network' not found
```

**Solutions:**
1. Check network name spelling and case
2. Verify network exists in the datacenter/node
3. Check network permissions
4. List available networks:
   ```bash
   # vSphere - use vSphere Client
   # Proxmox
   pvesh get /nodes/{node}/network
   ```

### Error: Insufficient Resources

**Symptoms:**
```
Error: Not enough resources available
```

**Solutions:**
1. Check available CPU, memory, and storage
2. Reduce VM resource requirements in tfvars
3. Free up resources on the host
4. Choose different datastore/storage with more space

## Ansible Issues

### Error: Host Unreachable

**Symptoms:**
```
UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh"}
```

**Solutions:**
1. Verify VM is running and has network connectivity
2. Check SSH key permissions:
   ```bash
   chmod 600 /path/to/private/key
   ```
3. Test SSH connection manually:
   ```bash
   ssh -i /path/to/key ubuntu@vm-ip
   ```
4. Check cloud-init completion:
   ```bash
   ssh -i /path/to/key ubuntu@vm-ip
   sudo cloud-init status
   ```
5. Verify inventory file is correct

### Error: Permission Denied (SSH)

**Symptoms:**
```
Permission denied (publickey)
```

**Solutions:**
1. Verify SSH public key was properly injected via cloud-init
2. Check SSH key format and encoding
3. Ensure private key matches public key
4. Check cloud-init logs:
   ```bash
   sudo cat /var/log/cloud-init.log
   ```

### Error: Package Installation Failed

**Symptoms:**
```
FAILED! => {"msg": "Failed to update apt cache"}
```

**Solutions:**
1. Check internet connectivity from VM
2. Verify DNS resolution:
   ```bash
   nslookup packages.gitlab.com
   ```
3. Check firewall rules
4. Update package sources manually:
   ```bash
   sudo apt update
   ```

### Error: GitLab Installation Timeout

**Symptoms:**
```
FAILED! => {"msg": "Timeout waiting for GitLab to be ready"}
```

**Solutions:**
1. Increase timeout values in playbook
2. Check VM resources (GitLab needs adequate memory)
3. Monitor GitLab installation:
   ```bash
   sudo gitlab-ctl status
   sudo gitlab-ctl tail
   ```
4. Check disk space:
   ```bash
   df -h
   ```

## GitLab Issues

### GitLab Not Starting

**Symptoms:**
- GitLab services fail to start
- 502 Bad Gateway errors

**Solutions:**
1. Check GitLab status:
   ```bash
   sudo gitlab-ctl status
   ```
2. Reconfigure GitLab:
   ```bash
   sudo gitlab-ctl reconfigure
   ```
3. Check logs:
   ```bash
   sudo gitlab-ctl tail
   ```
4. Verify system resources:
   ```bash
   free -h
   df -h
   ```
5. Check for port conflicts:
   ```bash
   sudo netstat -tlnp | grep :80
   sudo netstat -tlnp | grep :443
   ```

### Initial Root Password Not Found

**Symptoms:**
```
cat: /etc/gitlab/initial_root_password: No such file or directory
```

**Solutions:**
1. Check if file exists with different name:
   ```bash
   sudo find /etc/gitlab -name "*password*"
   ```
2. Reset root password:
   ```bash
   sudo gitlab-rake "gitlab:password:reset[root]"
   ```
3. Check GitLab logs for password generation:
   ```bash
   sudo grep -i password /var/log/gitlab/gitlab-rails/production.log
   ```

### SSL Certificate Issues

**Symptoms:**
- Browser security warnings
- SSL handshake failures

**Solutions:**
1. Check certificate files exist:
   ```bash
   sudo ls -la /etc/gitlab/ssl/
   ```
2. Verify certificate validity:
   ```bash
   sudo openssl x509 -in /etc/gitlab/ssl/cert.crt -text -noout
   ```
3. Regenerate self-signed certificate:
   ```bash
   sudo rm /etc/gitlab/ssl/*
   sudo gitlab-ctl reconfigure
   ```
4. For production, use proper SSL certificates

## LDAP Issues

### LDAP Connection Failed

**Symptoms:**
```
LDAP connection test failed
```

**Solutions:**
1. Test LDAP connection manually:
   ```bash
   ldapsearch -x -H ldap://ldap.example.com -D "cn=admin,dc=example,dc=com" -W
   ```
2. Check LDAP server accessibility:
   ```bash
   telnet ldap.example.com 389
   ```
3. Verify LDAP configuration in GitLab:
   ```bash
   sudo gitlab-rake gitlab:ldap:check
   ```
4. Check GitLab LDAP logs:
   ```bash
   sudo tail -f /var/log/gitlab/gitlab-rails/production.log | grep -i ldap
   ```

### LDAP Users Not Syncing

**Symptoms:**
- Users can't login with LDAP credentials
- LDAP users not appearing in GitLab

**Solutions:**
1. Check LDAP user filter:
   ```bash
   sudo gitlab-rake gitlab:ldap:check_users
   ```
2. Verify user attributes mapping
3. Check LDAP bind DN permissions
4. Test specific user:
   ```bash
   sudo gitlab-rake gitlab:ldap:check_users[username]
   ```

## Network Issues

### VM Can't Access Internet

**Symptoms:**
- Package installation fails
- DNS resolution fails
- Can't reach external services

**Solutions:**
1. Check VM network configuration:
   ```bash
   ip addr show
   ip route show
   ```
2. Test DNS resolution:
   ```bash
   nslookup google.com
   ```
3. Check gateway connectivity:
   ```bash
   ping gateway-ip
   ```
4. Verify network configuration in cloud-init
5. Check hypervisor network settings

### GitLab Not Accessible from Browser

**Symptoms:**
- Connection timeout
- Connection refused
- 502 Bad Gateway

**Solutions:**
1. Check GitLab is running:
   ```bash
   sudo gitlab-ctl status
   ```
2. Verify firewall rules:
   ```bash
   sudo ufw status
   ```
3. Check nginx configuration:
   ```bash
   sudo gitlab-ctl tail nginx
   ```
4. Test local connectivity:
   ```bash
   curl -I http://localhost
   ```
5. Check external URL configuration in GitLab

## Performance Issues

### GitLab Running Slowly

**Symptoms:**
- Slow page loads
- Timeouts
- High resource usage

**Solutions:**
1. Check system resources:
   ```bash
   htop
   iotop
   ```
2. Increase VM resources (CPU, memory)
3. Optimize GitLab configuration:
   ```bash
   # Edit /etc/gitlab/gitlab.rb
   unicorn['worker_processes'] = 4
   postgresql['shared_buffers'] = "512MB"
   ```
4. Disable unused GitLab features
5. Check disk I/O performance

### High Memory Usage

**Symptoms:**
- Out of memory errors
- System becomes unresponsive

**Solutions:**
1. Increase VM memory
2. Optimize GitLab memory settings:
   ```bash
   # Edit /etc/gitlab/gitlab.rb
   unicorn['worker_memory_limit_min'] = "400 * 1 << 20"
   unicorn['worker_memory_limit_max'] = "650 * 1 << 20"
   ```
3. Disable memory-intensive features
4. Monitor memory usage:
   ```bash
   free -h
   ps aux --sort=-%mem | head
   ```

## Useful Debugging Commands

### System Information
```bash
# System resources
free -h
df -h
lscpu
lsblk

# Network information
ip addr show
ip route show
ss -tlnp

# Process information
ps aux
systemctl status
```

### GitLab Specific
```bash
# GitLab status and logs
sudo gitlab-ctl status
sudo gitlab-ctl tail
sudo gitlab-rake gitlab:check

# GitLab configuration
sudo gitlab-rake gitlab:env:info
sudo cat /etc/gitlab/gitlab.rb | grep -v "^#" | grep -v "^$"

# Database information
sudo gitlab-psql -c "SELECT version();"
sudo gitlab-rake db:migrate:status
```

### Cloud-init Debugging
```bash
# Cloud-init status and logs
sudo cloud-init status
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log

# Cloud-init configuration
sudo cat /etc/cloud/cloud.cfg
sudo cloud-init query -a
```

## Getting Help

If you're still experiencing issues:

1. **Check GitLab Documentation**: https://docs.gitlab.com/
2. **GitLab Community Forum**: https://forum.gitlab.com/
3. **Terraform Documentation**: https://registry.terraform.io/
4. **Ansible Documentation**: https://docs.ansible.com/
5. **Create GitHub Issue**: Include logs, configuration, and error messages

## Log Locations

### Important Log Files
- **Cloud-init**: `/var/log/cloud-init.log`, `/var/log/cloud-init-output.log`
- **GitLab**: `/var/log/gitlab/`
- **System**: `/var/log/syslog`, `/var/log/auth.log`
- **SSH**: `/var/log/auth.log`
- **Ansible**: Local execution logs

### Collecting Logs for Support
```bash
# Create support bundle
mkdir gitlab-support-$(date +%Y%m%d)
cd gitlab-support-$(date +%Y%m%d)

# System information
uname -a > system-info.txt
free -h > memory-info.txt
df -h > disk-info.txt
ip addr show > network-info.txt

# GitLab information
sudo gitlab-ctl status > gitlab-status.txt
sudo gitlab-rake gitlab:env:info > gitlab-env.txt
sudo cp /etc/gitlab/gitlab.rb gitlab-config.rb

# Recent logs
sudo tail -1000 /var/log/gitlab/gitlab-rails/production.log > gitlab-production.log
sudo tail -1000 /var/log/cloud-init.log > cloud-init.log

# Create archive
cd ..
tar -czf gitlab-support-$(date +%Y%m%d).tar.gz gitlab-support-$(date +%Y%m%d)/
