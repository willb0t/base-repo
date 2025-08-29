# Platform Selection
variable "platform" {
  description = "Platform to deploy to (vsphere or proxmox)"
  type        = string
  validation {
    condition     = contains(["vsphere", "proxmox"], var.platform)
    error_message = "Platform must be either 'vsphere' or 'proxmox'."
  }
}

# VM Configuration
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "gitlab-ce"
}

variable "vm_cpu" {
  description = "Number of CPU cores for the VM"
  type        = number
  default     = 4
}

variable "vm_memory" {
  description = "Amount of memory in MB for the VM"
  type        = number
  default     = 8192
}

variable "vm_disk_size" {
  description = "Disk size in GB for the VM"
  type        = number
  default     = 50
}

variable "vm_network" {
  description = "Network name for the VM"
  type        = string
}

variable "vm_domain" {
  description = "Domain name for the VM"
  type        = string
  default     = "local"
}

# Network Configuration
variable "use_static_ip" {
  description = "Whether to use static IP configuration"
  type        = bool
  default     = false
}

variable "static_ip" {
  description = "Static IP address for the VM (if use_static_ip is true)"
  type        = string
  default     = ""
}

variable "gateway" {
  description = "Gateway IP address (if use_static_ip is true)"
  type        = string
  default     = ""
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

# SSH Configuration
variable "ssh_public_key" {
  description = "SSH public key for VM access (leave empty to generate new key pair)"
  type        = string
  default     = ""
}

variable "ssh_private_key_file" {
  description = "Path to SSH private key file (used when ssh_public_key is provided)"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ssh_username" {
  description = "SSH username for VM access"
  type        = string
  default     = "ubuntu"
}

# VMware vSphere Configuration
variable "vsphere_server" {
  description = "vSphere server hostname or IP"
  type        = string
  default     = ""
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
  default     = ""
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vsphere_datacenter" {
  description = "vSphere datacenter name"
  type        = string
  default     = ""
}

variable "vsphere_cluster" {
  description = "vSphere cluster name"
  type        = string
  default     = ""
}

variable "vsphere_datastore" {
  description = "vSphere datastore name"
  type        = string
  default     = ""
}

variable "vsphere_template" {
  description = "vSphere VM template name (Ubuntu 22.04+ with cloud-init)"
  type        = string
  default     = ""
}

# Proxmox Configuration
variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g., https://proxmox.example.com:8006/api2/json)"
  type        = string
  default     = ""
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
  default     = ""
}

variable "proxmox_api_token" {
  description = "Proxmox API token secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = ""
}

variable "proxmox_template" {
  description = "Proxmox VM template name (Ubuntu 22.04+ cloud image)"
  type        = string
  default     = ""
}

# GitLab Configuration
variable "gitlab_external_url" {
  description = "External URL for GitLab (e.g., https://gitlab.example.com)"
  type        = string
  default     = ""
}

# LDAP Configuration (Optional)
variable "enable_ldap" {
  description = "Enable LDAP integration for GitLab"
  type        = bool
  default     = false
}

variable "ldap_host" {
  description = "LDAP server hostname"
  type        = string
  default     = ""
}

variable "ldap_port" {
  description = "LDAP server port"
  type        = number
  default     = 389
}

variable "ldap_bind_dn" {
  description = "LDAP bind DN"
  type        = string
  default     = ""
}

variable "ldap_password" {
  description = "LDAP bind password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ldap_base" {
  description = "LDAP base DN for user searches"
  type        = string
  default     = ""
}

variable "ldap_user_filter" {
  description = "LDAP user filter"
  type        = string
  default     = ""
}
