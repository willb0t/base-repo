# VM Information
output "vm_name" {
  description = "Name of the created virtual machine"
  value       = var.vm_name
}

output "vm_ip" {
  description = "IP address of the virtual machine"
  value       = var.platform == "vsphere" ? module.vsphere_vm[0].vm_ip : module.proxmox_vm[0].vm_ip
}

output "vm_fqdn" {
  description = "Fully qualified domain name of the virtual machine"
  value       = "${var.vm_name}.${var.vm_domain}"
}

# SSH Connection Information
output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh -i ${var.ssh_public_key != "" ? var.ssh_private_key_file : "${path.module}/generated-ssh-key"} ${var.ssh_username}@${var.platform == "vsphere" ? module.vsphere_vm[0].vm_ip : module.proxmox_vm[0].vm_ip}"
}

output "ssh_username" {
  description = "SSH username for connecting to the VM"
  value       = var.ssh_username
}

output "ssh_private_key_file" {
  description = "Path to the SSH private key file"
  value       = var.ssh_public_key != "" ? var.ssh_private_key_file : "${path.module}/generated-ssh-key"
  sensitive   = true
}

# GitLab Information
output "gitlab_url" {
  description = "GitLab external URL"
  value       = var.gitlab_external_url != "" ? var.gitlab_external_url : "http://${var.platform == "vsphere" ? module.vsphere_vm[0].vm_ip : module.proxmox_vm[0].vm_ip}"
}

output "gitlab_initial_setup" {
  description = "Instructions for initial GitLab setup"
  value = <<-EOT
    1. SSH to the VM: ${var.ssh_public_key != "" ? var.ssh_private_key_file : "${path.module}/generated-ssh-key"} ${var.ssh_username}@${var.platform == "vsphere" ? module.vsphere_vm[0].vm_ip : module.proxmox_vm[0].vm_ip}
    2. Run the Ansible playbook: ansible-playbook -i ansible/inventories/hosts ansible/playbooks/gitlab-setup.yml
    3. Access GitLab at: ${var.gitlab_external_url != "" ? var.gitlab_external_url : "http://${var.platform == "vsphere" ? module.vsphere_vm[0].vm_ip : module.proxmox_vm[0].vm_ip}"}
    4. Initial root password is stored in: /etc/gitlab/initial_root_password
  EOT
}

# Platform-specific Information
output "platform" {
  description = "Platform used for deployment"
  value       = var.platform
}

output "platform_details" {
  description = "Platform-specific deployment details"
  value = var.platform == "vsphere" ? {
    server     = var.vsphere_server
    datacenter = var.vsphere_datacenter
    cluster    = var.vsphere_cluster
    datastore  = var.vsphere_datastore
    template   = var.vsphere_template
  } : {
    api_url  = var.proxmox_api_url
    node     = var.proxmox_node
    template = var.proxmox_template
  }
  sensitive = true
}

# Network Configuration
output "network_config" {
  description = "Network configuration details"
  value = {
    use_static_ip = var.use_static_ip
    static_ip     = var.use_static_ip ? var.static_ip : null
    gateway       = var.use_static_ip ? var.gateway : null
    dns_servers   = var.dns_servers
    network       = var.vm_network
  }
}

# Ansible Inventory
output "ansible_inventory_file" {
  description = "Path to the generated Ansible inventory file"
  value       = "${path.module}/ansible/inventories/hosts"
}

# LDAP Configuration (if enabled)
output "ldap_enabled" {
  description = "Whether LDAP integration is enabled"
  value       = var.enable_ldap
}

output "ldap_config" {
  description = "LDAP configuration details (if enabled)"
  value = var.enable_ldap ? {
    host        = var.ldap_host
    port        = var.ldap_port
    bind_dn     = var.ldap_bind_dn
    base        = var.ldap_base
    user_filter = var.ldap_user_filter
  } : null
  sensitive = true
}
