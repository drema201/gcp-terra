provider "google" {
  project     = "postgretrial"    
  region      = "us-central1"    
  zone        = "us-central1-b"    
}

provider "null" {
}


resource "null_resource" "test" {
  provisioner "local-exec" {
    command = "echo local"
  }
}