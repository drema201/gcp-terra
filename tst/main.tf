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



resource "google_compute_image" "image-base" {
    name="image-base"
    source_image=data.google_compute_image.image-terra-ora.self_link

    guest_os_features {
      type = "MULTI_IP_SUBNET"
    }
}