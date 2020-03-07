variable ipv4_address {}

resource "cloudflare_record" "echo1" {
  zone_id = data.cloudflare_zones.workflow_zone.zones[0].id
  name    = "echo1"
  value   = var.ipv4_address
  type    = "A"
  ttl     = 600
}

resource "cloudflare_record" "echo2" {
  zone_id = data.cloudflare_zones.workflow_zone.zones[0].id
  name    = "echo2"
  value   = var.ipv4_address
  type    = "A"
  ttl     = 600
}

resource "cloudflare_record" "argo" {
  zone_id = data.cloudflare_zones.workflow_zone.zones[0].id
  name    = "argo"
  value   = var.ipv4_address
  type    = "A"
  ttl     = 600
}
