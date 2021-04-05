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
    command = "echo ${replace(var.PREFIX,'/24','')}"
  }
}