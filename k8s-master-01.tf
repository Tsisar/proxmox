resource "proxmox_virtual_environment_vm" "k8s_master_01" {
  vm_id       = 100
  name        = "k8s-master-01"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = "pve"

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  agent {
    enabled = true
  }

  network_device {
    bridge    = "vmbr0"
  }

  disk {
    datastore_id = "local-btrfs"
    file_id      = proxmox_virtual_environment_file.debian_cloud_image.id
    interface    = "scsi0"
    size         = 60
  }

  serial_device {} # The Debian cloud image expects a serial port to be present

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }

  initialization {
    datastore_id = "local-btrfs"
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id

    ip_config {
      ipv4 {
        address = "192.168.88.40/24"
        gateway = "192.168.88.1"
      }
    }
  }
}