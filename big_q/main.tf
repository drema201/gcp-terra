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

resource "google_bigquery_dataset_iam_binding" "reader" {
  dataset_id = google_bigquery_dataset.ds_test.dataset_id
  role       = "roles/bigquery.dataViewer"

  members = [
    "user:gcloudpostgr@gmail.com",
  ]
}

resource "google_bigquery_table_iam_member" "member" {
  project = google_bigquery_table.default.project
  dataset_id = google_bigquery_table.default.dataset_id
  table_id = google_bigquery_table.default.table_id
  role = "roles/bigquery.dataViewer"
  member = "user:gcloudpostgr@gmail.com"
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

resource "google_bigquery_job" "extjob" {
  job_id     = "job_extract"

  extract {
    destination_uris = ["${google_storage_bucket.for-bg.url}/extract/names_us_p"]

    source_table {
      project_id = "bigquery-public-data"
      dataset_id = "usa_names"
      table_id   = "usa_1910_2013"
    }

    destination_format = "PARQUET"
  }
}

resource "google_bigquery_job" "extjob_a" {
  job_id     = "job_extract_a"

  extract {
    destination_uris = ["${google_storage_bucket.for-bg.url}/extract/names_us_a"]

    source_table {
      project_id = "bigquery-public-data"
      dataset_id = "usa_names"
      table_id   = "usa_1910_2013"
    }

    destination_format = "AVRO"
  }
}

resource "google_bigquery_job" "sqljob_b" {
  job_id     = "job_query_b1"

  query {
    query = "select * from bigquery-public-data.usa_names.usa_1910_2013 WHERE name like 'I%' AND year=1941"
    create_disposition = "CREATE_IF_NEEDED"
    write_disposition ="WRITE_TRUNCATE"

    destination_table {
      project_id = "postgretrial"
      dataset_id = "${google_bigquery_dataset.ds_test.dataset_id}"
      table_id   = "usa_1910_2013_1"
    }
  }
}
//bq ls --jobs
// bq --location=US show --job=true job_query_create1
// bq --location=US --project_id=postgretrial rm -j job_query_create1
resource "google_bigquery_job" "sqljob_create1" {
  depends_on = [
    google_bigquery_job.sqljob_b,
  ]
  job_id     = "job_query_create5"

  query {
    query = "CREATE MATERIALIZED VIEW postgretrial.${google_bigquery_dataset.ds_test.dataset_id}.my_mv_table    OPTIONS (enable_refresh = true, refresh_interval_minutes = 60) AS SELECT count(1), state FROM  ds_test.usa_1910_2013_1 GROUP BY state"
    create_disposition = ""
    write_disposition =""

  }
}


resource "google_bigquery_table" "default" {
  dataset_id = google_bigquery_dataset.ds_test.dataset_id
  table_id   = "links-day"

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

resource "google_bigquery_table" "names_a" {
  dataset_id = google_bigquery_dataset.ds_test.dataset_id
  table_id   = "names_avro"

  external_data_configuration {
    autodetect    = true
    source_format = "AVRO"

    source_uris = [
      "gs://${google_storage_bucket.for-bg.name}/extract/names_us_a",
    ]
  }
}

resource "google_bigquery_table" "names_p" {
  dataset_id = google_bigquery_dataset.ds_test.dataset_id
  table_id   = "names_parquet"

  external_data_configuration {
    autodetect    = true
    source_format = "PARQUET"

    source_uris = [
      "gs://${google_storage_bucket.for-bg.name}/extract/names_us_p",
    ]
  }
}

resource "null_resource" "localcp" {
  provisioner "local-exec" {
    command = "gsutil cp lostpolicy_2012-2015.axls gs://${google_storage_bucket.for-bg.name}/tables/excel/lostpolicy_2012-2015.axls"
  }

}
