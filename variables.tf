#----------------
# Environment Vars
#----------------
variable "hcloud_token" {
  type        = string
  sensitive   = true
  description = "Hetzner Cloud Token for provider"
}

variable "hcloud_dns_token" {
  type= string
  sensitive = true
  description = "Hetzner DNS Token for provider" 
}

variable "dns_zone" {
  type = string
  descripdescription = "DNS Zone your Nextcloud server should be in"  
}

variable "dns_hostname" {
  type = string
  descrdescription = "Hostname of your server¨"
}

variable "ansible_user" {
  type = string
  description = "Username for the ansible user"  
  default = "ci"
}

variable "ansible_ssh_key" {
  type = string
  description = "Path to SSH public key to inject into Cloud server for ansible user"
}

variable "ansible_ssh_port" {
  type = number
  default = 58222 
  description = "SSH port for Cloud server"
}

variable "common_labels" {
  type = map(string)
  default = {}
  description = "Map of labels to set on resources"
}

#----------------
# Server Vars
#----------------
variable "server_image" {
  type        = string
  default     = "debian-11"
  description = "Image to use for the Cloud server"
}

variable "server_type" {
  type        = string
  default     = "cx11"
  description = "Server type to use for the Cloud server"
}

variable "server_location" {
  type    = string
  default = "hel1"
  description = "Location where your Cloud server should be located"
}

variable "server_backups" {
  type        = bool
  description = "Enable server backups if needed"
  default     = false
}

variable "ipv6_only" {
  type = bool
  description = "Do you really need IPv4?"
  default = true
}

#----------------
# Volume Vars
#----------------
variable "volume_size" {
  type        = number
  description = "Size of the data volume"
  default     = 50
}

