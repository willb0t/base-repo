# VM Configuration
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "vm_cpu" {
  description = "Number of CPU cores for the VM"
  type        = number
}

variable "vm_memory" {
  description = "Amount of memory in MB for the VM"
  type        = number
}

variable "vm_disk_size" {
  description = "Disk size in GB for the VM"
  type        = number
}

variable "vm_network" {
  description = "Network bridge name for the VM"
  type        = string
}

variable "vm_domain" {
  description = "Domain name for the VM"
  type        = string
}

variable "vlan_tag" {
  description = "VLAN tag for the network interface"
  type        = number
  default     = -1
}

# Proxmox Configuration
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "proxmox_template" {
  description = "Proxmox VM template name (Ubuntu 22.04+ cloud image)"
  type        = string
}

variable "proxmox_storage" {
  description = "Proxmox storage name for VM disks"
  type        = string
  default     = "local-lvm"
}

# Network Configuration
variable "use_static_ip" {
  description = "Whether to use static IP configuration"
  type        = bool
}

variable "static_ip" {
  description = "Static IP address for the VM"
  type        = string
}

variable "netmask" {
  description = "Network mask for static IP (e.g., 24 for /24)"
  type        = number
  default     = 24
}

variable "gateway" {
  description = "Gateway IP address"
  type        = string
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
}

# SSH Configuration
variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "ssh_username" {
  description = "SSH username for VM access"
  type        = string
}

variable "ssh_private_key_file" {
  description = "Path to SSH private key file"
  type        = string
  default     = ""
}

# GitLab Configuration
variable "gitlab_external_url" {
  description = "External URL for GitLab"
  type        = string
}
