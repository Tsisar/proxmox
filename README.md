# K8S cluster on ProxmoxVE
Based on article: https://olav.ninja/deploying-kubernetes-cluster-on-proxmox-part-1
## Dependencies:
- Terraform: https://www.terraform.io/
- Terraform Provider for Proxmox: https://github.com/bpg/terraform-provider-proxmox
- Direnv: https://direnv.net/
  
To use direnv, create a file called .envrc and add the following:
```text
export PROXMOX_VE_USERNAME=root@pam
export PROXMOX_VE_PASSWORD=<your proxmox password>
```
- Ansible https://docs.ansible.com/

## Config

After installation, you can connect to the cluster via SSH:
```shell
ssh user@k8s-master-01
```
Check available nodes:
```shell
sudo -i
kubectl get nodes
```
You can view the config:
```shell
kubectl config view
```
or a file:
```
$HOME/.kube/config
```

## Kubernetes Dashboard
https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

Creating a Service Account

We are creating Service Account with the name admin-user in namespace kubernetes-dashboard first:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
```
Creating a ClusterRoleBinding:
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

Getting a Bearer Token for ServiceAccount:
```shell
kubectl -n kubernetes-dashboard create token admin-user
```
Getting a long-lived Bearer Token for ServiceAccount:
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

Accessing the Dashboard:
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-nodeport
  namespace: kubernetes-dashboard
spec:
  ports:
  - name: https
    protocol: TCP
    port: 8443
    targetPort: 8443
    nodePort: 30010
  selector:
    k8s-app: kubernetes-dashboard
  type: NodePort
```

## ArgoCD
https://argo-cd.readthedocs.io/en/stable/

Install Argo CD:
```shell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
Accessing the ArgoCD:
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/component: server
    app.kubernetes.io/name: argocd-server
    app.kubernetes.io/part-of: argocd
  name: argocd-server-nodeport
  namespace: argocd
spec:
  ports:
  - name: https
    protocol: TCP
    port: 8080
    targetPort: 8080
    nodePort: 30011
  selector:
    app.kubernetes.io/name: argocd-server
  type: NodePort
```
Installing ArgoCD Command Line Interface:
```shell
wget https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd-linux-amd64
sudo mv argocd-linux-amd64 /usr/local/bin/argocd
```
- The ArgoCD initial password:
```shell
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode; echo
```
Login Using The CLI:
```shell
argocd login k8s-master-01:30011
```
Change the password using the command
```shell
argocd account update-password
```