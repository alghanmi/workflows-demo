## Create Kubernetes Cluster

```sh
terraform init
terraform apply
```

## Kubernetes Cluster Setup

```sh
mkdir -p ~/.kube
jq --raw-output '.resources[] | select(.type=="digitalocean_kubernetes_cluster")  | .instances[0] | .attributes | .kube_config[0] | .raw_config' terraform.tfstate > ~/.kube/config

helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```

### Dashboard & Monitoring

```sh
kubectl create namespace kube-monitoring
helm install metrics-server stable/metrics-server --namespace kube-monitoring --values config/metrics-server-values.yaml
```

### Ingress Controller

```sh
kubectl create namespace ingress
helm install nginx-ingress stable/nginx-ingress --namespace ingress --set controller.publishService.enabled=true
```

```sh
kubectl apply -f echo1.yaml
kubectl apply -f echo2.yaml
kubectl apply -f echo-ingress.yaml

export KUBE_INGRESS_IP=$(kubectl -n ingress get svc nginx-ingress-controller -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $KUBE_INGRESS_IP

curl -H 'Host: echo1.alghanmi.net' http://$KUBE_INGRESS_IP
curl -H 'Host: echo2.alghanmi.net' http://$KUBE_INGRESS_IP

curl -k -H 'Host: echo1.alghanmi.net' http://$KUBE_INGRESS_IP

terraform apply -var="ipv4_address=$KUBE_INGRESS_IP"
curl echo1.alghanmi.net echo2.alghanmi.net
curl -k https://echo{1,2}.alghanmi.net

```

### Cert Manager

```sh
helm repo add jetstack https://charts.jetstack.io
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.14/deploy/manifests/00-crds.yaml
kubectl get crd | grep 'cert-manager.io'

kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager --namespace cert-manager
kubectl get pods --namespace cert-manager

sed "s/EMAIL_ADDRESS/$ACME_EMAIL/" config/letsencrypt-prod-issuer.yaml | kubectl create -f -
kubectl get certificate
kubectl describe certificate echo-tls

```
