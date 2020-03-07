## Create Kubernetes Cluster

```sh
cd terraform-cluster
terraform init
terraform apply
```

### Kubernetes Cluster Setup

```sh
mkdir -p ~/.kube
jq --raw-output '.resources[] | select(.type=="digitalocean_kubernetes_cluster")  | .instances[0] | .attributes | .kube_config[0] | .raw_config' terraform.tfstate > ~/.kube/config
cd ..

helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```

### Monitoring

```sh
kubectl create namespace kube-monitoring
helm install metrics-server stable/metrics-server --namespace kube-monitoring --values config/metrics-server-values.yaml
```

### Ingress Controller

```sh
kubectl create namespace ingress
helm install nginx-ingress stable/nginx-ingress --namespace ingress --set controller.publishService.enabled=true
kubectl -n ingress get svc nginx-ingress-controller
```

### Cert Manager
```sh
helm repo add jetstack https://charts.jetstack.io
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.14/deploy/manifests/00-crds.yaml

kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager --namespace cert-manager
kubectl get pods --namespace cert-manager

sed "s/EMAIL_ADDRESS/$ACME_EMAIL/" config/letsencrypt-prod-issuer.yaml | kubectl create -f -
sed "s/EMAIL_ADDRESS/$ACME_EMAIL/" config/letsencrypt-staging-issuer.yaml | kubectl create -f -
```

### DNS Settings

```sh
kubectl -n ingress get svc nginx-ingress-controller
export KUBE_INGRESS_IP=$(kubectl -n ingress get svc nginx-ingress-controller -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $KUBE_INGRESS_IP
cd terraform-dns
terraform init
terraform apply -var="ipv4_address=$KUBE_INGRESS_IP"
cd ..
```

### Argo

```sh
kubectl create namespace argo
kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo/stable/manifests/install.yaml

kubectl create namespace workflows
kubectl -n workflows create rolebinding default-admin --clusterrole=admin --serviceaccount=default:default
```

### Ingress
```sh
kubectl create -f config/echo-service.yaml
kubectl create -f config/echo-ingress.yaml
```

## Destroy

```sh
cd terraform-cluster
terraform destroy -auto-approve
cd ..

cd terraform-dns
terraform destroy -auto-approve
cd ..

for lb in $(doctl compute load-balancer list -o json | jq --raw-output '.[] | .id'); do doctl compute load-balancer delete --force $lb; done
```
