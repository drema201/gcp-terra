data "google_compute_image" "image-terra-io" {
  provider = google-beta
  family  = "centos-7"
  project = "centos-cloud"
}


resource "google_compute_instance" "terra-io1" {
  provider = google-beta
  name           = "terra-inst-io1"
  machine_type   = "e2-standard-2"
  zone           = "us-central1-c"
  can_ip_forward = false
#  service_account {
#     email = data.google_compute_default_service_account.default.email
#     scopes = ["cloud-platform"]
#  }
  boot_disk {
    initialize_params {
      image = data.google_compute_image.image-terra.self_link
    }
  }
  network_interface {
    network = "default"
  }
}

