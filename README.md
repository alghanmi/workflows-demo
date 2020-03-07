# Path to GitOps &ndash; Migrating to Workflows
The following lab material goes with the _Path to GitOps &ndash; Migrating to Workflows_ presentation. The goal of this presentation is to discuss migrating from existing monolithic CI/CD piplines for applications and migrate them to _Workflows_.

## Lab Material
This lab uses [Digital Ocean Managed Kubernetes](https://www.digitalocean.com/products/kubernetes/) to host this topic. Please follow these in-order as you follow the presentation.

### Create Kubernetes Cluster

```sh
cd terraform-cluster
terraform init
terraform apply
```

#### Kubernetes Cluster Setup

```sh
mkdir -p ~/.kube
jq --raw-output '.resources[] | select(.type=="digitalocean_kubernetes_cluster")  | .instances[0] | .attributes | .kube_config[0] | .raw_config' terraform.tfstate > ~/.kube/config
cd ..

helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```

#### Monitoring

```sh
kubectl create namespace kube-monitoring
helm install metrics-server stable/metrics-server --namespace kube-monitoring --values config/metrics-server-values.yaml
```

#### Ingress Controller - Deploy

```sh
kubectl create namespace ingress
helm install nginx-ingress stable/nginx-ingress --namespace ingress --set controller.publishService.enabled=true
kubectl -n ingress get svc nginx-ingress-controller
```

#### Cert Manager - Deploy
```sh
helm repo add jetstack https://charts.jetstack.io
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.14/deploy/manifests/00-crds.yaml

kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager --namespace cert-manager
```

#### Cert Manager - Setup Let's Encrypt Certificate `ClusterIssuer`

```sh
sed "s/EMAIL_ADDRESS/$ACME_EMAIL/" config/letsencrypt-prod-issuer.yaml | kubectl create -f -
sed "s/EMAIL_ADDRESS/$ACME_EMAIL/" config/letsencrypt-staging-issuer.yaml | kubectl create -f -
```

#### Ingress Controller - DNS Settings

```sh
kubectl -n ingress get svc nginx-ingress-controller
export KUBE_INGRESS_IP=$(kubectl -n ingress get svc nginx-ingress-controller -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $KUBE_INGRESS_IP
cd terraform-dns
terraform init
terraform apply -var="ipv4_address=$KUBE_INGRESS_IP"
cd ..
```

#### Argo - Deploy

```sh
kubectl create namespace argo
kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo/stable/manifests/install.yaml

kubectl create namespace workflows
kubectl -n workflows create rolebinding default-admin --clusterrole=admin --serviceaccount=default:default
```

#### Echo Test Service - Ingress

```sh
kubectl create -f config/echo-service.yaml
kubectl create -f config/echo-ingress.yaml
```

#### Argo - Ingress

```sh
kubectl create -f config/argo-server-ingress.yaml
```

### Lab Clean-up

```sh
cd terraform-cluster
terraform destroy -auto-approve
cd ..

cd terraform-dns
terraform destroy -auto-approve
cd ..

for lb in $(doctl compute load-balancer list -o json | jq --raw-output '.[] | .id'); do doctl compute load-balancer delete --force $lb; done
```
