provider "google" {
  project     = "postgretrial"    
  region      = "us-central1"    
  zone        = "us-central1-b"    
}    

resource "null_resource" "test" {
  provisioner "local-exec" {
    command = "echo local"
  }
}