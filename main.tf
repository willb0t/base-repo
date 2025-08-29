terraform {
  required_version = ">= 1.0"
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.4"
    }
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Generate SSH key pair if not provided
resource "tls_private_key" "gitlab_ssh" {
  count     = var.ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  count           = var.ssh_public_key == "" ? 1 : 0
  content         = tls_private_key.gitlab_ssh[0].private_key_pem
  filename        = "${path.module}/generated-ssh-key"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  count    = var.ssh_public_key == "" ? 1 : 0
  content  = tls_private_key.gitlab_ssh[0].public_key_openssh
  filename = "${path.module}/generated-ssh-key.pub"
}

# Conditional module loading based on platform
module "vsphere_vm" {
  count  = var.platform == "vsphere" ? 1 : 0
  source = "./terraform/modules/vsphere"

  # VM Configuration
  vm_name          = var.vm_name
  vm_cpu           = var.vm_cpu
  vm_memory        = var.vm_memory
  vm_disk_size     = var.vm_disk_size
  vm_network       = var.vm_network
  vm_domain        = var.vm_domain

  # vSphere Configuration
  vsphere_server     = var.vsphere_server
  vsphere_user       = var.vsphere_user
  vsphere_password   = var.vsphere_password
  vsphere_datacenter = var.vsphere_datacenter
  vsphere_cluster    = var.vsphere_cluster
  vsphere_datastore  = var.vsphere_datastore
  vsphere_template   = var.vsphere_template

  # Network Configuration
  use_static_ip = var.use_static_ip
  static_ip     = var.static_ip
  gateway       = var.gateway
  dns_servers   = var.dns_servers

  # SSH Configuration
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : tls_private_key.gitlab_ssh[0].public_key_openssh
  ssh_username   = var.ssh_username

  # GitLab Configuration
  gitlab_external_url = var.gitlab_external_url
}

module "proxmox_vm" {
  count  = var.platform == "proxmox" ? 1 : 0
  source = "./terraform/modules/proxmox"

  # VM Configuration
  vm_name          = var.vm_name
  vm_cpu           = var.vm_cpu
  vm_memory        = var.vm_memory
  vm_disk_size     = var.vm_disk_size
  vm_network       = var.vm_network
  vm_domain        = var.vm_domain

  # Proxmox Configuration
  proxmox_api_url      = var.proxmox_api_url
  proxmox_api_token_id = var.proxmox_api_token_id
  proxmox_api_token    = var.proxmox_api_token
  proxmox_node         = var.proxmox_node
  proxmox_template     = var.proxmox_template

  # Network Configuration
  use_static_ip = var.use_static_ip
  static_ip     = var.static_ip
  gateway       = var.gateway
  dns_servers   = var.dns_servers

  # SSH Configuration
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : tls_private_key.gitlab_ssh[0].public_key_openssh
  ssh_username   = var.ssh_username

  # GitLab Configuration
  gitlab_external_url = var.gitlab_external_url
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/ansible/inventories/hosts.tpl", {
    vm_ip        = var.platform == "vsphere" ? module.vsphere_vm[0].vm_ip : module.proxmox_vm[0].vm_ip
    ssh_username = var.ssh_username
    ssh_key_file = var.ssh_public_key != "" ? var.ssh_private_key_file : "${path.module}/generated-ssh-key"
    vm_name      = var.vm_name
  })
  filename = "${path.module}/ansible/inventories/hosts"
}
