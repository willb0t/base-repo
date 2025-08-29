# VM Information
output "vm_id" {
  description = "ID of the created virtual machine"
  value       = vsphere_virtual_machine.vm.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = vsphere_virtual_machine.vm.name
}

output "vm_ip" {
  description = "IP address of the virtual machine"
  value       = vsphere_virtual_machine.vm.default_ip_address
}

output "vm_uuid" {
  description = "UUID of the virtual machine"
  value       = vsphere_virtual_machine.vm.uuid
}

# Network Information
output "vm_network_interfaces" {
  description = "Network interfaces of the virtual machine"
  value       = vsphere_virtual_machine.vm.network_interface
}

# vSphere Information
output "vm_datacenter" {
  description = "Datacenter where the VM is deployed"
  value       = var.vsphere_datacenter
}

output "vm_cluster" {
  description = "Cluster where the VM is deployed"
  value       = var.vsphere_cluster
}

output "vm_datastore" {
  description = "Datastore where the VM is stored"
  value       = var.vsphere_datastore
}

# SSH Connection Information
output "ssh_connection_command" {
  description = "SSH connection command for the VM"
  value       = "ssh -i ${var.ssh_private_key_file} ${var.ssh_username}@${vsphere_virtual_machine.vm.default_ip_address}"
}
