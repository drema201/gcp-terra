provider "google" {
  project     = "postgretrial"
  region      = "us-central1"
  zone        = "us-central1-b"
}

data "google_compute_default_service_account" "default" {
}

data "google_compute_image" "image-terra-cent7" {
  provider = google-beta
  family  = "centos-7"
  project = "centos-cloud"

}



resource "google_compute_image" "image-base" {
    name="image-base"
    source_image=data.google_compute_image.image-terra-cent7.self_link

    guest_os_features {
      type = "MULTI_IP_SUBNET"
    }
}

resource "google_compute_instance" "terra-test-1" {
  provider = google-beta
  name           = "terra-test-01"
  machine_type   = "e2-standard-2"
  zone           = "us-central1-b"
  can_ip_forward = false
  service_account {
     email = data.google_compute_default_service_account.default.email
     scopes = ["cloud-platform"]
     }

  boot_disk {
    initialize_params {
      image = google_compute_image.image-base.self_link
    }
  }
  network_interface {
    network = "default"
    access_config {
   //network_tier = "PREMIUM"
    }
  }
}