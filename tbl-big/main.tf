provider "google" {
  project     = "postgretrial"
  region      = "us-central1"
  zone        = "us-central1-b"
}

resource "google_storage_bucket" "for-btbl" {
  name          = "postgretrial-bigtbl"
  location      = "US"

  lifecycle_rule {
    condition {
      age = 3
    }
    action {
      type = "Delete"
    }
  }
  uniform_bucket_level_access = true
}

resource "google_bigtable_instance" "production-instance" {
  name = "bus-instance"
  deletion_protection = false

  cluster {
    cluster_id   = "bus-cluster"
    num_nodes    = 2
    storage_type = "SSD"
  }

  labels = {
    my-label = "tst-label"
  }
}

resource "google_bigtable_table" "table_a" {
  name          = "bus-data"
  instance_name = google_bigtable_instance.production-instance.name
  split_keys    = ["a", "b", "c"]
  column_family {
    family = "cf"
  }
  column_family {
    family = "family2"
  }
  lifecycle {
    prevent_destroy = false
  }
}

//gcloud beta dataflow jobs run import-bus-data-15 --gcs-location gs://dataflow-templates/latest/GCS_SequenceFile_to_Cloud_Bigtable --verbosity debug --num-workers=2 --max-workers=2 --parameters bigtableProject=postgretrial,bigtableInstanceId=bus-instance,bigtableTableId=bus-data,sourcePattern=gs://cloud-bigtable-public-datasets/bus-data/*
resource "google_dataflow_job" "bigtbl_dfj" {
  name = "import-bus-data-2"
  template_gcs_path = "gs://dataflow-templates/latest/GCS_SequenceFile_to_Cloud_Bigtable"
  temp_gcs_location = "${google_storage_bucket.for-btbl.url}/tmp"
  zone = "us-central1-b"
  max_workers = 2
  //enable_streaming_engine = true
  parameters = {
    bigtableProject="postgretrial",
    bigtableInstanceId="bus-instance",
    bigtableTableId="${google_bigtable_table.table_a.name}",
    sourcePattern="gs://cloud-bigtable-public-datasets/bus-data/*"
  }
  on_delete = "cancel"
}