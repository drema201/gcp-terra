provider "google" {
  project     = "postgretrial"
  region      = "us-central1"
  zone        = "us-central1-c"
}

resource "google_storage_bucket" "for-dataprc-fs" {
  name          = "postgretrial-dataproc-fs-bucket"
  location      = "US"
  uniform_bucket_level_access = true
}


resource "null_resource" "localcp" {
  provisioner "local-exec" {
    command = "gsutil cp hello-world.py gs://${google_storage_bucket.for-dataprc-fs.name}/examples/pyspark/hello-world.py"
  }
  provisioner "local-exec" {
    command = "gsutil cp count_by_subreddit.py gs://${google_storage_bucket.for-dataprc-fs.name}/examples/pyspark/count_by_subreddit.py"
  }
}