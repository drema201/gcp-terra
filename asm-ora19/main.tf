provider "google" {
  project     = "postgretrial"    
  region      = "us-central1"    
  zone        = "us-central1-b"    
}    

data "google_compute_default_service_account" "default" {    
}    
    
data "google_compute_image" "image-terra-ora" {    
  provider = google-beta    
  family  = "centos-7"    
  project = "centos-cloud"    
}    

resource "google_compute_disk" "disk-b" {
    name    = "disk-b1-data"
    type    = "pd-balanced"
    zone    = "us-central1-b"
    size    = "25"
}

resource "google_compute_disk" "disk-c" {
    name    = "disk-c1-data"
    type    = "pd-balanced"
    zone    = "us-central1-b"
    size    = "25"
}

resource "google_compute_disk" "disk-d" {
    name    = "disk-d1-data"
    type    = "pd-balanced"
    zone    = "us-central1-b"
    size    = "25"
}

resource "google_compute_disk" "disk-e" {
    name    = "disk-e1-data"
    type    = "pd-balanced"
    zone    = "us-central1-b"
    size    = "25"
}



resource "google_compute_instance" "terra-asm-1" {    
  provider = google-beta    
  name           = "terra-inst-asm-01"    
  machine_type   = "e2-standard-2"    
  zone           = "us-central1-b"    
  can_ip_forward = false    
  service_account {    
     email = data.google_compute_default_service_account.default.email    
     scopes = ["cloud-platform"]    
     }    
    
  boot_disk {    
    initialize_params {    
      image = data.google_compute_image.image-terra-ora.self_link    
    }    

  network_interface {    
    network = "default"    
    access_config {    
   //network_tier = "PREMIUM"    
    }    

  attached_disk {
        source      = google_compute_disk.disk-b.self_link
        device_name = google_compute_disk.disk-b.name
  }
  attached_disk {
        source      = google_compute_disk.disk-c.self_link
        device_name = google_compute_disk.disk-c.name
  }
  attached_disk {
        source      = google_compute_disk.disk-d.self_link
        device_name = google_compute_disk.disk-d.name
  }
  attached_disk {
        source      = google_compute_disk.disk-e.self_link
        device_name = google_compute_disk.disk-e.name
  }

}