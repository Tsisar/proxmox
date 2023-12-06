# K8S cluster on ProxmoxVE home Lab
Based on article: https://olav.ninja/deploying-kubernetes-cluster-on-proxmox-part-1
## Dependencies:
- Terraform: https://www.terraform.io/
- Provider for Proxmox: https://github.com/bpg/terraform-provider-proxmox
- Ansible https://docs.ansible.com/
- Direnv: https://direnv.net/
  
To use direnv, create a file called .envrc and add the following:
```text
export PROXMOX_VE_USERNAME=root@pam
export PROXMOX_VE_PASSWORD=<your proxmox password>
```

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

Creating sample user

Creating a Service Account:
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
```shell
kubectl apply -f .\k8s\kubernetes-dashboard\service-account.yaml
```
Now we need to find the token we can use to log in. Execute the following command:
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
```shell
kubectl apply -f .\k8s\kubernetes-dashboard\admin-user-secret.yaml
```
After Secret is created, we can execute the following command to get the token which saved in the Secret:

Linux:
```shell
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
```
Windows:
```shell
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath="{.data.token}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
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
```shell
kubectl apply -f .\k8s\kubernetes-dashboard\nodeport.yaml
```

## Dynamic Volume Provisioning
<span style="color:red;">NOT FOR PRODUCTION!</span>

https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/

Local Storage class.

Download rancher.io/local-path storage class:
```shell
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```
Check with:
```shell
kubectl get storageclass
```
Make this storage class (local-path) the default:
```shell
kubectl patch storageclass local-path -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}'
```

## ArgoCD
https://argo-cd.readthedocs.io/en/stable/

Install Argo CD:
```shell
kubectl create namespace argocd
```
```shell
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
```shell
kubectl apply -n argocd -f .\k8s\argocd\nodeport.yaml
```
Installing ArgoCD Command Line Interface:
```shell
wget https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
```
```shell
chmod +x argocd-linux-amd64
```
```shell
sudo mv argocd-linux-amd64 /usr/local/bin/argocd
```
The ArgoCD initial password:
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

# Monitoring

## Elasticsearch for Kubernetes

Elasticsearch is used as storage for Jaeger.

Currently 8.x ElasticSearch version is not compatible with Jaeger, hence we using version 7.17.15.

Elasticsearch is deployed using the Kubernetes Operator pattern. You can read in more detail in the article Elastic Cloud on Kubernetes https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-overview.html.

1. Install custom resource definitions:
```shell
kubectl create -f https://download.elastic.co/downloads/eck/2.10.0/crds.yaml
```
2. Install the operator with its RBAC rules:
```shell
kubectl apply -f https://download.elastic.co/downloads/eck/2.10.0/operator.yaml
```

3. Create the namespace `monitoring` for further deployment.
```shell
kubectl create namespace monitoring
```
4. Deploy an Elasticsearch cluster
```shell
kubectl apply -f .\k8s\elastic\elasticsearch.yaml
```
The operator automatically creates and manages Kubernetes resources to achieve the desired state of the Elasticsearch cluster. It may take up to a few minutes until all the resources are created and the cluster is ready for use.

5. Elasticsearch access
```shell
PASSWORD=$(kubectl -n monitoring  get secret elasticsearch-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
kubectl -n monitoring create secret generic jaeger-storage-secret --from-literal=ES_PASSWORD=${PASSWORD} --from-literal=ES_USERNAME=elastic
```
The command will automatically create jaeger-storage-secret for further use in Jaeger.


## Cert manager
https://cert-manager.io/

Install all cert-manager components:
```shell
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
```
Wait for cert-manager webhook to be ready

## Jaeger for Kubernetes
https://www.jaegertracing.io/docs/1.51/operator/
 
Installing the Operator
```shell
kubectl create namespace observability
```
```shell
kubectl create -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.51.0/jaeger-operator.yaml -n observability
```
Deploying the AllInOne image
```shell
kubectl apply -f .\k8s\jaeger\jaeger.yaml
```

Accessing the Dashboard:
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: jaeger
  name: jaeger-nodeport
  namespace: monitoring
spec:
  ports:
    - name: http-query
      protocol: TCP
      port: 16686
      targetPort: 16686
      nodePort: 30012
  selector:
    app: jaeger
  type: NodePort
```
```shell
kubectl apply -f .\k8s\jaeger\nodeport.yaml
```

## Rabbit MQ
https://medium.com/nerd-for-tech/deploying-rabbitmq-on-kubernetes-using-rabbitmq-cluster-operator-ef99f7a4e417

Install the RabbitMQ operator
```shell
kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml
```

Check if the components are healthy in the rabbitmq-system namespace
```shell
kubectl get all -o wide -n rabbitmq-system
```
Apply the RabbitMQ cluster
```shell
kubectl apply -f .\k8s\rabbitmq\rabbitmq.yaml
```