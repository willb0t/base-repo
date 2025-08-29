terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.4"
    }
  }
}

# Configure the VMware vSphere Provider
provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

# Data sources for vSphere objects
data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vm_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vsphere_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Create cloud-init user data
locals {
  cloud_init_user_data = base64encode(templatefile("${path.module}/cloud-init-user-data.yml", {
    ssh_public_key   = var.ssh_public_key
    ssh_username     = var.ssh_username
    vm_hostname      = var.vm_name
    vm_domain        = var.vm_domain
    use_static_ip    = var.use_static_ip
    static_ip        = var.static_ip
    gateway          = var.gateway
    dns_servers      = var.dns_servers
  }))
  
  cloud_init_meta_data = base64encode(templatefile("${path.module}/cloud-init-meta-data.yml", {
    vm_hostname = var.vm_name
    vm_domain   = var.vm_domain
  }))
}

# Create the virtual machine
resource "vsphere_virtual_machine" "vm" {
  name             = var.vm_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vm_folder

  num_cpus = var.vm_cpu
  memory   = var.vm_memory
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = var.vm_disk_size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = var.vm_name
        domain    = var.vm_domain
      }

      network_interface {
        ipv4_address = var.use_static_ip ? var.static_ip : null
        ipv4_netmask = var.use_static_ip ? var.netmask : null
      }

      ipv4_gateway    = var.use_static_ip ? var.gateway : null
      dns_server_list = var.dns_servers
    }
  }

  # Cloud-init configuration using vApp properties
  vapp {
    properties = {
      "guestinfo.userdata"          = local.cloud_init_user_data
      "guestinfo.userdata.encoding" = "base64"
      "guestinfo.metadata"          = local.cloud_init_meta_data
      "guestinfo.metadata.encoding" = "base64"
    }
  }

  # Wait for the VM to be ready
  wait_for_guest_net_timeout = 5
  wait_for_guest_ip_timeout  = 5

  lifecycle {
    ignore_changes = [
      clone[0].template_uuid,
    ]
  }
}

# Wait for SSH to be available
resource "null_resource" "wait_for_ssh" {
  depends_on = [vsphere_virtual_machine.vm]

  provisioner "remote-exec" {
    inline = ["echo 'SSH is ready'"]

    connection {
      type        = "ssh"
      host        = vsphere_virtual_machine.vm.default_ip_address
      user        = var.ssh_username
      private_key = file(var.ssh_private_key_file)
      timeout     = "5m"
    }
  }
}
