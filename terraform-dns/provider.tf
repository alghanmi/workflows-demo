variable cf_dns_token {}

provider "cloudflare" {
  version   = "~> 2.0"
  api_token = var.cf_dns_token
}
