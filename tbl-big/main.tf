provider "google" {
  project     = "postgretrial"
  region      = "us-central1"
  zone        = "us-central1-b"
}

resource "google_bigtable_instance" "production-instance" {
  name = "btbl-instance"

  cluster {
    cluster_id   = "bgtblclust"
    num_nodes    = 2
    storage_type = "SSD"
    deletion_protection = false
  }

  labels = {
    my-label = "tst-label"
  }
}

resource "google_bigtable_table" "table_a" {
  name          = "tbl_a"
  instance_name = google_bigtable_instance.production-instance.name
  split_keys    = ["a", "b", "c"]

  lifecycle {
    prevent_destroy = false
  }
}