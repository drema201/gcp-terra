provider "google" {
  project     = "postgretrial"
  region      = "us-central1"
  zone        = "us-central1-a"
}

provider "null" {
}


resource "google_compute_network" "comp-net" {
  name                    = "comp1-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "comp-subnet" {
  name          = "comp1-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.comp-net.id
}

resource "google_service_account" "comp-acc" {
  account_id   = "composer-env-account"
  display_name = "Test Service Account for Composer Environment"
}

resource "google_project_iam_member" "composer-worker" {
  role   = "roles/composer.worker"
  member = "serviceAccount:${google_service_account.comp-acc.email}"
}

resource "google_composer_environment" "compos-2" {
  name   = "compos-1"
  region = "us-central1"

  config {
    node_count = 3

    node_config {
      zone         = "us-central1-a"
      machine_type = "e2-medium"

      network    = google_compute_network.comp-net.id
      subnetwork = google_compute_subnetwork.comp-subnet.id

      service_account = google_service_account.comp-acc.name
    }

    software_config {
      airflow_config_overrides = {
        core-load_example = "True"
      }

      env_variables = {
        FOO = "bar"
      }

    }

  }

    provisioner "local-exec" {
      command = "echo 'test provis'"
    }
}


resource "google_storage_bucket" "for-compose" {
  name          = "compose-gs"
  location      = "US"

  uniform_bucket_level_access = true

}

resource "null_resource" "example1" {
  provisioner "local-exec" {
    command = "echo 'test provis2'"
  }
}