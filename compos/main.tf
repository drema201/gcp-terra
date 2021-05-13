provider "google" {
  project     = "postgretrial"
  region      = var.GCE_REGION
  zone        = var.GCE_ZONE
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
  region        = "${var.GCE_REGION}"
  network       = google_compute_network.comp-net.id
}

resource "google_service_account" "comp-acc" {
  account_id   = "composer-env-acc"
  display_name = "Test Service Account for Composer Environment"
}

resource "google_service_account_key" "comp-acc-key" {
  service_account_id = google_service_account.comp-acc.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_member" "composer-worker" {
  role   = "roles/composer.worker"
  member = "serviceAccount:${google_service_account.comp-acc.email}"
}
resource "google_project_iam_member" "composer-worker-1" {
  role   = "roles/dataflow.developer"
  member = "serviceAccount:${google_service_account.comp-acc.email}"
}

resource "google_project_iam_member" "composer-worker-2" {
  role   = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.comp-acc.email}"
}

resource "google_project_iam_member" "composer-worker-3" {
  role   = "roles/bigquery.dataEditor"
  member = "serviceAccount:${google_service_account.comp-acc.email}"
}

resource "google_project_iam_member" "composer-worker-4" {
  role   = "roles/bigquery.jobUser"
  member = "serviceAccount:${google_service_account.comp-acc.email}"
}

resource "google_project_iam_member" "composer-worker-5" {
  role   = "roles/bigquery.user"
  member = "serviceAccount:${google_service_account.comp-acc.email}"
}

resource "google_composer_environment" "compos-3" {
  name   = "compos-3"
  region = "${var.GCE_REGION}"

  config {
    node_count = 3

    node_config {
      zone         = "${var.GCE_ZONE}"
      machine_type = "e2-medium"

      network    = google_compute_network.comp-net.id
      subnetwork = google_compute_subnetwork.comp-subnet.id

      service_account = google_service_account.comp-acc.name
      disk_size_gb = 30
    }

    software_config {
      airflow_config_overrides = {
        core-load_example = "False"
      }

      env_variables = {
        FOO = "bar"
      }

    }

  }

    provisioner "local-exec" {
      command = "echo 'INSIDE composer ENV'"
    }


    provisioner "local-exec" {
      command = <<EOF
gcloud composer environments run ${google_composer_environment.compos-3.name} --location ${google_composer_environment.compos-3.region}  variables --  --set project_id postgretrial
gcloud composer environments run ${google_composer_environment.compos-3.name} --location ${google_composer_environment.compos-3.region}  variables --  --set gce_region ${var.GCE_REGION}
gcloud composer environments run ${google_composer_environment.compos-3.name} --location ${google_composer_environment.compos-3.region}  variables --  --set gce_zone ${var.GCE_ZONE}
gcloud composer environments run ${google_composer_environment.compos-3.name} --location ${google_composer_environment.compos-3.region}  variables --  --set bucket_path gs://${google_storage_bucket.for-compose-3.name}
EOF
    }

}


resource "google_storage_bucket" "for-compose-3" {
  name          = "compose-gs"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true

}

output "env-bucket-out" {
  value = google_storage_bucket.for-compose-3.name
}

resource "null_resource" "after-bucket" {
  provisioner "local-exec" {
    command = "echo 'test provis2'"
  }
  provisioner "local-exec" {
    command = "gsutil cp transformCSVtoJSON.js gs://${google_storage_bucket.for-compose-3.name}/"
  }
  provisioner "local-exec" {
    command = "gsutil cp jsonSchema.json gs://${google_storage_bucket.for-compose-3.name}/"
  }
  provisioner "local-exec" {
    command = "gsutil cp inputFile.txt gs://${google_storage_bucket.for-compose-3.name}/"
  }

  depends_on = [
      google_storage_bucket.for-compose-3,
  ]
}

output "env-conf-out" {
  value = google_composer_environment.compos-3.config.0
}

resource "null_resource" "after-env" {
  provisioner "local-exec" {
    command = "echo 'test provis3'"
  }
  provisioner "local-exec" {
    command = "gsutil cp dags/composer-dataflow-dag.py ${google_composer_environment.compos-3.config.0.dag_gcs_prefix}/"
  }

  depends_on = [
      google_composer_environment.compos-3
  ]

}