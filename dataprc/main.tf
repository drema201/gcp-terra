provider "google" {
  project     = "postgretrial"
  region      = "us-central1"
  zone        = "us-central1-c"
}

data "google_compute_default_service_account" "default" {
}



