terraform {
  backend "http" {} # TF state from gitlab
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    hetznerdns = {
      source = "timohirt/hetznerdns"
    }
  }
}