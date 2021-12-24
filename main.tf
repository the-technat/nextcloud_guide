locals {
  user_data = templatefile("${path.module}/cloud_init.yml",{
    ansible_user = var.ansible_user
    ansible_ssh_port = var.ansible_ssh_port
    ansible_ssh_key = var.ansible_ssh_key
  })
  server_name = "${var.dns_hostname}.${var.dns_zone}"
}

resource "hcloud_ssh_key" "ansible_key" {
  name = "Terraform Ansible Key"
  public_key = file(var.ansible_ssh_key)
}

resource "hcloud_server" "nc_instance" {
  name        = local.server_name
  server_type = data.hcloud_server_type.server_type.name
  location = data.hcloud_location.server_location.name
  image       = data.hcoud_image.server_image.name
  user_data = local.user_data
  ssh_keys = [hcloud_ssh_key.ansible_key.public_key] # Add the ansible ssh-key as key for root to prevent mails with root passwords 
  backups = var.server_backups
  labels =  merge(var.common_labels, {
    "created-by" = "terraform"
    "configured-by" = "ansible"
  })
}

resource "hcloud_volume" "nc_volume" {
  name      = local.server_name
  size      = var.volume_size
  server_id = hcloud_server.nc_instance.id
  automount = false
  labels = merge(var.common_labels, {
    "created-by" = "terraform"
    "configured-by" = "ansible"
  })
}

resource "hetznerdns_record" "nc_a" {
  count = var.ipv6_only ? false : true
  zone_id = data.hetznerdns_zone.dns_zone.id
  name = var.dns_hostname
  value = hcloud_server.nc_instance.ipv4_address
  type = "A"
  ttl= 60
}

resource "hetznerdns_record" "nc_aaaa" {
  zone_id = data.hetznerdns_zone.dns_zone.id
  name = var.dns_hostname
  value = hcloud_server.nc_instance.ipv6_address
  type = "AAAA"
  ttl= 60
}

