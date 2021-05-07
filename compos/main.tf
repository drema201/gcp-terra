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

resource "google_composer_environment" "compos-1" {
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

      pypi_packages = {
        numpy = ""
        scipy = "==1.1.0"
      }

      env_variables = {
        FOO = "bar"
      }

    }

  }
}

resource "google_bigquery_dataset" "comp_ds" {
  dataset_id                  = "average_weather"
  friendly_name               = "Composer_WEATHER"
  description                 = "This is a test description"
  location                    = "US"
  default_table_expiration_ms = 3600000

  labels = {
    env = "default"
  }

  access {
    role          = "OWNER"
    user_by_email = google_service_account.bqowner.email
  }

}

resource "google_service_account" "bqowner" {
  account_id = "bqowner"
}

resource "google_bigquery_table" "average_weather" {
  dataset_id = google_bigquery_dataset.comp_ds.dataset_id
  table_id   = "average_weather"

  deletion_protection = NO

  labels = {
    env = "default"
  }

  schema = <<EOF
[
{
"name": "location",
"type": "GEOGRAPHY",
"mode": "REQUIRED"
},
{
"name": "average_temperature",
"type": "INTEGER",
"mode": "REQUIRED"
},
{
"name": "month",
"type": "STRING",
"mode": "REQUIRED"
},
{
"name": "inches_of_rain",
"type": "NUMERIC"
},
{
"name": "is_current",
"type": "BOOLEAN"
},
{
"name": "latest_measurement",
"type": "DATE"
}
]
EOF

}

resource "google_storage_bucket" "for-compose" {
  name          = "compose-gs"
  location      = "US"

  uniform_bucket_level_access = true

}
