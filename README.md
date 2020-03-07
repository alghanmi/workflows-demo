# Path to GitOps &ndash; Migrating to Workflows

The following lab material goes with the _Path to GitOps &ndash; Migrating to Workflows_ presentation. The goal of this presentation is to discuss migrating from existing monolithic CI/CD piplines for applications and migrate them to _Workflows_.

## Lab Material

This lab uses [Digital Ocean Managed Kubernetes](https://www.digitalocean.com/products/kubernetes/) to host this topic. Please follow these in-order as you follow the presentation.

### Initial Prep

1. Install [Terraform](https://www.terraform.io/downloads.html)
1. Install `doctl` the [DigitalOcean CLI](https://github.com/digitalocean/doctl#installing-doctl) (Optional)
1. Install [Argo CLI](https://argoproj.github.io/docs/argo/docs/getting-started.html)

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
```

#### Argo - Ingress

```sh
# Deploying Test Service for deubgging
kubectl create -f config/echo-service.yaml
kubectl create -f config/echo-ingress.yaml

kubectl create -f config/argo-server-ingress.yaml
```

## Workflow Demos

### RBAC

```sh
kubectl create namespace workflows
kubectl -n workflows create rolebinding default-admin --clusterrole=admin --serviceaccount=workflows:default
```

### WF1 - Hello World

```sh
kubectl create -f workflows/hello-world.yaml
kubectl -n workflows get wf
export WF=$(kubectl -n workflows get wf | grep '^hello-world' | head -1 | awk '{ print $1 }')
kubectl -n workflows get wf $WF
kubectl -n workflows get po --selector=workflows.argoproj.io/workflow=$WF
kubectl -n workflows logs $WF -c main
```

### WF2 - Coinflip

```sh
argo -n workflows submit  --watch workflows/coinflip.yaml
argo -n workflows list
export WF=$(kubectl -n workflows get wf | grep '^coinflip' | head -1 | awk '{ print $1 }')
argo -n workflows get $WF
```
You can always see the pods logs using `argo -n workflows logs`

### WF3 - Coinflip Recursive

```sh
argo -n workflows submit  --watch workflows/coinflip-recursive.yaml
```


## Lab Clean-up

```sh
cd terraform-cluster
terraform destroy -auto-approve
cd ..

cd terraform-dns
terraform destroy -auto-approve
cd ..

for lb in $(doctl compute load-balancer list -o json | jq --raw-output '.[] | .id'); do doctl compute load-balancer delete --force $lb; done

find . -name "terraform.tfstate*" -exec rm {} \;
```
