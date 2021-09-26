provider "google" {
  project     = "postgretrial"
  region      = "us-central1"
  zone        = "us-central1-c"
}

data "google_compute_default_service_account" "default" {
}

resource "google_storage_bucket" "for-dataprc" {
  name          = "postgretrial-dataproc-staging-bucket"
  location      = "US"

  uniform_bucket_level_access = true

}

resource "google_storage_bucket" "for-dataprc-tmp" {
  name          = "postgretrial-dataproc-temp-bucket"
  location      = "US"

  uniform_bucket_level_access = true

}

resource "google_storage_bucket" "for-dataprc-fs" {
  name          = "postgretrial-dataproc-fs-bucket"
  location      = "US"

  uniform_bucket_level_access = true

}


resource "google_dataproc_cluster" "dataprc-ml" {
  name     = "dataprc-ml"
  region   = "us-central1"
  graceful_decommission_timeout = "120s"
  labels = {
    foo = "bar"
  }

  cluster_config {
    lifecycle_config {
      idle_delete_ttl = "20m"
      auto_delete_time = "2120-01-01T12:00:00.01Z"
    }

    staging_bucket = google_storage_bucket.for-dataprc.name
    temp_bucket = google_storage_bucket.for-dataprc-tmp.name


    gce_cluster_config {
      tags = ["foo", "bar"]
      # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
      service_account = data.google_compute_default_service_account.default.email
      service_account_scopes = [
        "cloud-platform"
      ]
    }

    master_config {
      num_instances = 1
      machine_type  = "n1-standard-4"
      disk_config {
        boot_disk_size_gb = 30
        num_local_ssds    = 2
      }
    }

    worker_config {
      num_instances    = 2
      machine_type  = "n1-standard-2"
      disk_config {
        boot_disk_size_gb = 30
        num_local_ssds    = 1
      }
    }


    # Override or set some custom properties
    software_config {
      image_version = "1.3.7-deb9"
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "true"
      #  "core:fs.defaultFS" = "gs://postgretrial-dataproc-fs-bucket"
      }
    }

    # You can define multiple initialization_action blocks
    initialization_action {
      script      = "gs://dataproc-initialization-actions/stackdriver/stackdriver.sh"
      timeout_sec = 300
    }
  }
}