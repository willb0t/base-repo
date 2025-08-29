# VM Information
output "vm_id" {
  description = "ID of the created virtual machine"
  value       = proxmox_vm_qemu.vm.vmid
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = proxmox_vm_qemu.vm.name
}

output "vm_ip" {
  description = "IP address of the virtual machine"
  value       = proxmox_vm_qemu.vm.default_ipv4_address
}

# Network Information
output "vm_network_interfaces" {
  description = "Network interfaces of the virtual machine"
  value       = proxmox_vm_qemu.vm.network
}

# Proxmox Information
output "vm_node" {
  description = "Proxmox node where the VM is deployed"
  value       = proxmox_vm_qemu.vm.target_node
}

output "vm_template" {
  description = "Template used to create the VM"
  value       = var.proxmox_template
}

output "vm_storage" {
  description = "Storage where the VM disks are stored"
  value       = var.proxmox_storage
}

# SSH Connection Information
output "ssh_connection_command" {
  description = "SSH connection command for the VM"
  value       = "ssh -i ${var.ssh_private_key_file} ${var.ssh_username}@${proxmox_vm_qemu.vm.default_ipv4_address}"
}
