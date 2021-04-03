provider "google" {
  project     = "postgretrial"    
  region      = "us-central1"    
  zone        = "us-central1-b"    
}    

provisioner "local-exec" {
    command = "echo local"
  }