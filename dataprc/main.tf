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

resource "google_dataproc_cluster" "dataprc-ml" {
  name     = "dataprc-ml"
  region   = "us-central1"
  graceful_decommission_timeout = "120s"
  labels = {
    foo = "bar"
  }

  cluster_config {
    staging_bucket = google_storage_bucket.for-dataprc.name

    master_config {
      num_instances = 1
      machine_type  = "e2-medium"
      disk_config {
        boot_disk_size_gb = 30
      }
    }

    worker_config {
      num_instances    = 2
      disk_config {
        boot_disk_size_gb = 30
        num_local_ssds    = 1
      }
    }

    preemptible_worker_config {
      num_instances = 2
    }

    # Override or set some custom properties
    software_config {
      image_version = "1.3.7-deb9"
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "true"
      }
    }



    # You can define multiple initialization_action blocks
    initialization_action {
      script      = "gs://dataproc-initialization-actions/spark-nlp/spark-nlp.sh"
      timeout_sec = 90
    }
  }
}