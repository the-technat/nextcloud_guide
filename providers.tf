provider "hcloud" {
  token = var.hcloud_token
}
provider "hetznerdns" {
  apitoken = var.hcloud_dns_token
}