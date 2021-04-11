provider "google" {
  project     = "postgretrial"    
  region      = "us-central1"    
  zone        = "us-central1-b"    
}

provider "null" {
}

variable "PREFIX" {
description ="prefix"
type=string
default="10.0.0.0/24"
}


resource "null_resource" "test" {
  provisioner "local-exec" {
    command = "echo '${replace(var.PREFIX,"/24","")}'"
  }

}

resource "null_resource" "test2" {

  provisioner "local-exec" {
    command = "echo '${cidrhost(var.PREFIX,0)}'"
  }

}

resource "google_compute_address" "pubnetwork" {
  name = "public-ipv4-address"
  address_type = "EXTERNAL"
}

resource "google_compute_address" "pubnetwork-2" {
  name = "public-ipv4-address-2"
  address_type = "EXTERNAL"
}

data "google_compute_address" "data-net1" {
  self_link = google_compute_address.pubnetwork.self_link
}

data "google_compute_address" "data-net2" {
  self_link = google_compute_address.pubnetwork-2.self_link
}


output "net-1" {
  value = data.google_compute_address.data-net1
}

output "net-2" {
  value = data.google_compute_address.data-net2
}

