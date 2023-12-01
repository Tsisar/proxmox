# K8S cluster on ProxmoxVE
Based on article: https://olav.ninja/deploying-kubernetes-cluster-on-proxmox-part-1
## Dependencies:
- Terraform: https://www.terraform.io/
- Terraform Provider for Proxmox: https://github.com/bpg/terraform-provider-proxmox
- Direnv: https://direnv.net/
  
To use direnv, create a file called .envrc and add the following:
```
export PROXMOX_VE_USERNAME=root@pam
export PROXMOX_VE_PASSWORD=<your proxmox password>
```
- Ansible https://docs.ansible.com/

## Config

After installation, you can connect to the cluster via SSH:
```shell
ssh user@k8s-master-01
```
Перевірити доступні ноди:
```shell
sudo -i
kubectl get nodes
```
Конфіг можна переглянути за:
```shell
kubectl config view
```
або файл
```
$HOME/.kube/config
```

## Kubernetes Dashboard
https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

- Creating a Service Account

We are creating Service Account with the name admin-user in namespace kubernetes-dashboard first.
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
```
- Creating a ClusterRoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
```

- Getting a Bearer Token for ServiceAccount
```shell
kubectl -n kubernetes-dashboard create token admin-user
```
- Getting a long-lived Bearer Token for ServiceAccount
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: "admin-user"   
type: kubernetes.io/service-account-token  
```
After Secret is created, we can execute the following command to get the token which saved in the Secret:
```shell
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
```
