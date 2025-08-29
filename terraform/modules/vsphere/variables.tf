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
  description = "Network name for the VM"
  type        = string
}

variable "vm_domain" {
  description = "Domain name for the VM"
  type        = string
}

variable "vm_folder" {
  description = "vSphere folder for the VM"
  type        = string
  default     = ""
}

# vSphere Configuration
variable "vsphere_server" {
  description = "vSphere server hostname or IP"
  type        = string
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_datacenter" {
  description = "vSphere datacenter name"
  type        = string
}

variable "vsphere_cluster" {
  description = "vSphere cluster name"
  type        = string
}

variable "vsphere_datastore" {
  description = "vSphere datastore name"
  type        = string
}

variable "vsphere_template" {
  description = "vSphere VM template name (Ubuntu 22.04+ with cloud-init)"
  type        = string
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
