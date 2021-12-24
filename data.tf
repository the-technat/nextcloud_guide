data "hcloud_location" "server_location¨" {
  name = var.server_location
}

data "hcloud_server_type" "server_type" {
  name = var.server_type
}

data "hcloud_image" "server_image" {
  name = var.server_image
}

data "hetznerdns_zone" "dns_zone" {
  name = var.dns_zone
}

