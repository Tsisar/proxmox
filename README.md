# K8S cluster on ProxmoxVE
Based on article: https://olav.ninja/deploying-kubernetes-cluster-on-proxmox-part-1
## Dependencies:
- Terraform: https://www.terraform.io/
- Terraform Provider for Proxmox: https://github.com/bpg/terraform-provider-proxmox
- Direnv: https://direnv.net/
  
  To use direnv, create a file called .envrc and add the following:
  ````
  export PROXMOX_VE_USERNAME=root@pam
  export PROXMOX_VE_PASSWORD=<your proxmox password>
  ````
- Ansible https://docs.ansible.com/