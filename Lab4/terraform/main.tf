terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.1"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key for the ansible user"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# 1. Base Cloud Image (Ubuntu 22.04 LTS)
resource "libvirt_volume" "ubuntu2204_base" {
  name   = "ubuntu-22.04-base"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.disk-kvm.img"
  format = "qcow2"
}

# 2. Volumes for VMs
resource "libvirt_volume" "vm_worker_volume" {
  name           = "vm-worker.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu2204_base.id
  format         = "qcow2"
  size           = 10737418240 # 10 GB
}

resource "libvirt_volume" "vm_db_volume" {
  name           = "vm-db.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu2204_base.id
  format         = "qcow2"
  size           = 10737418240 # 10 GB
}

# 3. Create Cloud-Init datas
resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  pool      = "default"
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    public_key = file(var.ssh_public_key_path)
  })
}

# 4. Define Network (Bridged or NAT)
# Use the default network which is usually NAT with DHCP

# 5. Define VMs
resource "libvirt_domain" "worker" {
  name   = "vm-worker"
  memory = 1024
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
  disk {
    volume_id = libvirt_volume.vm_worker_volume.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

resource "libvirt_domain" "db" {
  name   = "vm-db"
  memory = 1024
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.vm_db_volume.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

output "worker_ip" {
  value = libvirt_domain.worker.network_interface[0].addresses[0]
}

output "db_ip" {
  value = libvirt_domain.db.network_interface[0].addresses[0]
}

# Generate Ansible inventory dynamically
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl",
    {
      worker_ip = libvirt_domain.worker.network_interface[0].addresses[0],
      db_ip     = libvirt_domain.db.network_interface[0].addresses[0]
    }
  )
  filename = "${path.module}/../ansible/inventory.ini"
}
