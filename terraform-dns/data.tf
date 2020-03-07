variable "zone_name" {}

data "cloudflare_zones" "workflow_zone" {
  filter {
    name   = var.zone_name
    status = "active"
    paused = false
  }
}
