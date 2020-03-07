resource "digitalocean_kubernetes_cluster" "workflow-demo" {
  name    = "workflow-demo"
  version = "1.16.6-do.0"

  region = "sfo2"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 3
  }

  tags = ["workflow", "demo"]
}

provider "kubernetes" {
  load_config_file = false
  host             = digitalocean_kubernetes_cluster.workflow-demo.endpoint
  token            = digitalocean_kubernetes_cluster.workflow-demo.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.workflow-demo.kube_config[0].cluster_ca_certificate
  )
}
