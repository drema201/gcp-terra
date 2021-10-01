provider "google" {
  project     = "postgretrial"
  region      = "us-central1"
  zone        = "us-central1-a"
}

data "google_compute_default_service_account" "default" {
}

resource "google_service_account" "proc-account" {
  account_id   = "dataproc-service-account-id"
  display_name = "Service Account for DataProc"
}

resource "google_dataproc_cluster_iam_binding" "editor" {
  cluster = "dataprc-cluster-ml"
  role    = "roles/editor"
  members = [
    "serviceAccount:${google_service_account.proc-account.email}",
  ]
}

resource "google_dataproc_workflow_template" "dataprc-template-ml" {
  provider = google-beta
  name = "dataprc-template-ml"
  location = "us-central1"

  placement {
    managed_cluster {
      cluster_name = "dataprc-cluster-ml"
      config {
        staging_bucket = "postgretrial-dataproc-staging-bucket"
        temp_bucket    = "postgretrial-dataproc-temp-bucket"

        gce_cluster_config {
          zone = "us-central1-a"
          tags = ["foo", "bar"]
          # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
          service_account = google_service_account.proc-account.email
          service_account_scopes = [
            "cloud-platform"
          ]
        }

        master_config {
          num_instances = 1
          machine_type = "n1-standard-4"
          disk_config {
            boot_disk_type = "pd-ssd"
            boot_disk_size_gb = 30
          }
        }

        worker_config {
          num_instances = 2
          machine_type = "n1-standard-2"
          disk_config {
            boot_disk_size_gb = 30
            num_local_ssds = 2
          }
        }

        # Override or set some custom properties
        software_config {
          properties = {
            "dataproc:dataproc.allow.zero.workers" = "true",
            "spark:spark.pyspark.python" = "/opt/conda/default/bin/python3",
            "spark-env:PYSPARK_PYTHON"="/opt/conda/default/bin/python3"
          }
        }

        # You can define multiple initialization_action blocks
        initialization_actions {
          executable_file      = "gs://dataproc-initialization-actions/stackdriver/stackdriver.sh"
        }


      }
    }
  }
  jobs {
    step_id = "hello"
    pyspark_job {
      main_python_file_uri = "gs://dataproc-examples-2f10d78d114f6aaec76462e3c310f31f/src/pyspark/hello-world/hello-world.py"
      properties = {
        "spark.logConf" = "true"
      }
    }
  }
  jobs {
    step_id = "count-reddit"
    prerequisite_step_ids = ["hello"]
    pyspark_job {
      main_python_file_uri = "gs://postgretrial-dataproc-fs-bucket/examples/pyspark/counts_by_subreddit.py"
      jar_file_uris = [
        "gs://spark-lib/bigquery/spark-bigquery-latest_2.12.jar"
      ]
    }
  }

}



resource "null_resource" "localcp" {
  provisioner "local-exec" {
    command = "gsutil cp ../hello-world.py gs://postgretrial-dataproc-fs-bucket/examples/pyspark/hello-world.py"
  }

  provisioner "local-exec" {
    command = "gsutil cp ../counts_by_subreddit.py gs://postgretrial-dataproc-fs-bucket/examples/pyspark/counts_by_subreddit.py"
  }
}
