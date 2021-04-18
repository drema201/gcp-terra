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

resource "google_compute_instance" "templ-cenos" {
  provider = google-beta
  name           = "terra-inst-centos"
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
    }

  network_interface {
    network = "default"
    access_config {
   //network_tier = "PREMIUM"
    }
  }
}

resource "google_compute_machine_image" "myimage" {
  provider        = google-beta
  name            = "myimage"
  source_instance = google_compute_instance.templ-cenos.self_link

}

resource "google_compute_image" "image-base" {
    name="image-base"
    source_image=projects/centos-cloud/global/images/centos-7-v20210401

    guest_os_features {
      type = "MULTI_IP_SUBNET"
    }
}