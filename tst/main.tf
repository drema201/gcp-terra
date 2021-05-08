data "google_compute_default_service_account" "default" {
}

resource "google_bigquery_dataset" "comp_ds" {
  dataset_id                  = "average_weather"
  friendly_name               = "Composer_WEATHER"
  description                 = "This is a test description"
  location                    = "US"
  default_table_expiration_ms = 3600000

  labels = {
    env = "default"
  }

  access {
    role          = "OWNER"
    user_by_email = google_service_account.bqowner.email
  }

  access {
    role          = "OWNER"
    user_by_email =  data.google_compute_default_service_account.default.email
  }

  access {
    role          = "OWNER"
    user_by_email =  "daviabidavi@gmail.com"
  }


}

resource "google_service_account" "bqowner" {
  account_id = "bqowner"
}

resource "google_bigquery_table" "average_weather" {
  dataset_id = google_bigquery_dataset.comp_ds.dataset_id
  table_id   = "average_weather"

  deletion_protection = false

  labels = {
    env = "default"
  }

  schema = <<EOF
[
{
"name": "location",
"type": "GEOGRAPHY",
"mode": "REQUIRED"
},
{
"name": "average_temperature",
"type": "INTEGER",
"mode": "REQUIRED"
},
{
"name": "month",
"type": "STRING",
"mode": "REQUIRED"
},
{
"name": "inches_of_rain",
"type": "NUMERIC"
},
{
"name": "is_current",
"type": "BOOLEAN"
},
{
"name": "latest_measurement",
"type": "DATE"
}
]
EOF

}

