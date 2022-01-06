provider "google" {
  project     = "postgretrial"    
  region      = "us-central1"    
  zone        = "us-central1-b"    
}    

data "google_compute_default_service_account" "default" {    
}    
    
data "google_compute_image" "image-terra-click" {
  provider = google-beta    
  family  = " ubuntu-20"
  project = "ubuntu-cloud"
}    
    
resource "google_compute_instance" "terra-click-1" {
  provider = google-beta    
  name           = "terra-inst-click-01"
  machine_type   = "e2-standard-2"    
  zone           = "us-central1-b"    
  can_ip_forward = false    
  service_account {    
     email = data.google_compute_default_service_account.default.email    
     scopes = ["cloud-platform"]    
     }    
    
  boot_disk {    
    initialize_params {    
      image = data.google_compute_image.image-terra-click.self_link
    }    
  }    
  network_interface {    
    network = "default"    
    access_config {    
   //network_tier = "PREMIUM"    
    }    
    
  }    
    
  metadata_startup_script = <<EOF
sleep 10
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E0C56BD4

sleep 3

EOF
}
    

