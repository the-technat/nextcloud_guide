output "ipv4_address" {
  description = "IPv4 address of Cloud server"
  value       = hcloud_server.nc_instance.ipv4_address
}

output "ipv6_address" {
  description = "IPv6 address of Cloud server"
  value       = hcloud_server.nc_instance.ipv6_address
}

output "ipv6_network" {
  description = "IPv6 net of Cloud server"
  value       = hcloud_server.nc_instance.ipv6_network
}

output "dns_fqdn" {
  value = "${var.dns_hostname}.${var.dns_zone}"
  description = "Fully qualified domain name of your nextcloud instance"
}

output "ansible_user" {
  value = var.ansible_user
  description = "User for ansible to configure the system"
}

output "ansible_ssh_key" {
  value = var.ansible_ssh_key
  description = "Public SSH key for ansible user"
}

output "ansible_ssh_port" {
  value = var.ansible_ssh_port
  description = "SSH port for Cloud server"
}