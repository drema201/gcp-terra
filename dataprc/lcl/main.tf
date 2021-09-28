provider "google" {
  project     = "postgretrial"
  region      = "us-central1"
  zone        = "us-central1-c"
}



resource "null_resource" "localcp" {
  provisioner "local-exec" {
    command = "gsutil cp hello-world.py gs://postgretrial-dataproc-fs-bucket/examples/pyspark/hello-world.py"
  }
  provisioner "local-exec" {
    command = "gsutil cp counts_by_subreddit.py gs://postgretrial-dataproc-fs-bucket/examples/pyspark/counts_by_subreddit.py"
  }
}