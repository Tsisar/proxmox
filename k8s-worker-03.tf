resource "proxmox_virtual_environment_vm" "k8s_worker_03" {
  vm_id       = 103
  name        = "k8s-worker-03"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = "pve"

  cpu {
    cores = 1
  }

  memory {
    dedicated = 2048
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
    size         = 80
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
        address = "192.168.88.43/24"
        gateway = "192.168.88.1"
      }
    }
  }
}