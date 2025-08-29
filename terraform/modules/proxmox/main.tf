terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

# Configure the Proxmox Provider
provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token    = var.proxmox_api_token
  pm_tls_insecure = true
}

# Create cloud-init user data
locals {
  cloud_init_user_data = templatefile("${path.module}/cloud-init-user-data.yml", {
    ssh_public_key   = var.ssh_public_key
    ssh_username     = var.ssh_username
    vm_hostname      = var.vm_name
    vm_domain        = var.vm_domain
    use_static_ip    = var.use_static_ip
    static_ip        = var.static_ip
    gateway          = var.gateway
    dns_servers      = var.dns_servers
  })
}

# Create the virtual machine
resource "proxmox_vm_qemu" "vm" {
  name        = var.vm_name
  target_node = var.proxmox_node
  clone       = var.proxmox_template
  full_clone  = true

  # VM Configuration
  cores   = var.vm_cpu
  memory  = var.vm_memory
  sockets = 1
  vcpus   = var.vm_cpu

  # Boot configuration
  boot    = "order=scsi0"
  scsihw  = "virtio-scsi-pci"
  os_type = "cloud-init"

  # Disk configuration
  disk {
    slot     = 0
    type     = "scsi"
    storage  = var.proxmox_storage
    size     = "${var.vm_disk_size}G"
    format   = "qcow2"
    ssd      = 1
    discard  = "on"
    iothread = 1
  }

  # Network configuration
  network {
    model  = "virtio"
    bridge = var.vm_network
    tag    = var.vlan_tag
  }

  # Cloud-init configuration
  cicustom = "user=local:snippets/${var.vm_name}-user-data.yml"
  
  # IP configuration
  ipconfig0 = var.use_static_ip ? "ip=${var.static_ip}/${var.netmask},gw=${var.gateway}" : "ip=dhcp"
  
  # DNS and search domain
  nameserver   = join(" ", var.dns_servers)
  searchdomain = var.vm_domain

  # SSH keys
  sshkeys = var.ssh_public_key

  # Agent configuration
  agent = 1

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }

  # Connection settings for provisioners
  connection {
    type        = "ssh"
    host        = self.default_ipv4_address
    user        = var.ssh_username
    private_key = file(var.ssh_private_key_file)
    timeout     = "5m"
  }

  # Wait for cloud-init to complete
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "echo 'Cloud-init completed successfully'"
    ]
  }
}

# Create cloud-init user data file on Proxmox
resource "null_resource" "cloud_init_user_data" {
  triggers = {
    user_data = local.cloud_init_user_data
  }

  # Upload cloud-init user data to Proxmox
  provisioner "local-exec" {
    command = <<-EOT
      # Create temporary file with cloud-init data
      echo '${local.cloud_init_user_data}' > /tmp/${var.vm_name}-user-data.yml
      
      # Upload to Proxmox (this would need to be customized based on your Proxmox setup)
      # For now, this is a placeholder - in practice, you'd use scp or similar
      echo "Cloud-init user data prepared for ${var.vm_name}"
    EOT
  }
}
