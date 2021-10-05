provider "google" {
  project     = "postgretrial"
  region      = "us-central1"
  zone        = "us-central1-b"
}

resource "google_storage_bucket" "for-bg" {
  name          = "postgretrial-bigq"
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

resource "google_bigquery_dataset" "ds_test" {
  dataset_id                  = "ds_test"
  friendly_name               = "test"
  description                 = "This is a test description"
  location                    = "US"
  default_table_expiration_ms = 3600000

  labels = {
    env = "default"
  }
}

resource "google_bigquery_table" "default" {
  dataset_id = google_bigquery_dataset.ds_test.dataset_id
  table_id   = "bar"

  time_partitioning {
    type = "DAY"
  }

  labels = {
    env = "default"
  }

  schema = <<EOF
[
  {
    "name": "permalink",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The Permalink"
  },
  {
    "name": "state",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "State where the head office is located"
  }
]
EOF

}

resource "google_bigquery_table" "sheet" {
  dataset_id = google_bigquery_dataset.ds_test.dataset_id
  table_id   = "sheet"

  external_data_configuration {
    autodetect    = true
    source_format = "GOOGLE_SHEETS"

    google_sheets_options {
      skip_leading_rows = 1
    }

    source_uris = [
      "gs://${google_storage_bucket.for-bg.name}/tables/excel/lostpolicy_2012-2015.xls",
    ]
  }
}

resource "null_resource" "localcp" {
  provisioner "local-exec" {
    command = "gsutil cp lostpolicy_2012-2015.xls gs://${google_storage_bucket.for-bg.name}/tables/excel/lostpolicy_2012-2015.xls"
  }

}
