
resource "google_dataproc_workflow_template" "template" {
  name = "template-example"
  location = var.GCE_REGION
  placement {
    managed_cluster {
      cluster_name = "my-cluster"
      config {
        gce_cluster_config {
          zone = "us-central1-a"
          tags = ["foo", "bar"]
        }
        master_config {
          num_instances = 1
          machine_type = "n1-standard-1"
          disk_config {
            boot_disk_type = "pd-ssd"
            boot_disk_size_gb = 15
          }
        }
        worker_config {
          num_instances = 2
          machine_type = "n1-standard-1"
          disk_config {
            boot_disk_size_gb = 10
            num_local_ssds = 2
          }
        }

        software_config {
          image_version = "1.3.7-deb9"
        }
      }
    }
  }
  jobs {
    step_id = "compute"
    spark_job {
      main_class = "org.apache.spark.examples.SparkPi"
      jar_file_uris="file:///usr/lib/spark/examples/jars/spark-examples.jar"
    }
  }

 }
