terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.38.1"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.88.21:8006/"
  username = "root@pam"
  password = "super_password"
  insecure = true
  ssh {
    agent = false
  }
}