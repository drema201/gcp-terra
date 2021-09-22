provider "google" {
  project     = "postgretrial"
  region      = "us-central1"
  zone        = "us-central1-c"
}

data "google_compute_default_service_account" "default" {
}

resource "google_pubsub_schema" "collect_io_sch" {
  name = "collect_io_sch"
  type = "AVRO"
  definition = "{\n  \"type\" : \"record\",\n  \"name\" : \"Avro\",\n  \"fields\" : [\n    {\n      \"name\" : \"NameField\",\n      \"type\" : \"string\"\n    },\n    {\n      \"name\" : \"GBSecField\",\n      \"type\" : \"int\"\n    }\n  ]\n}\n"
}

resource "google_pubsub_topic" "collect_io_topic" {
  name = "collect_io_topic"

  depends_on = [google_pubsub_schema.collect_io_sch]
  schema_settings {
    schema = "projects/postgretrial/schemas/collect_io_sch"
    encoding = "JSON"
  }
}

##dead letter topic
resource "google_pubsub_topic" "err_collect_io_topic" {
  name = "err_collect_io_topic"
  message_retention_duration = "3000s"
  retain_acked_messages      = true
}

#subscriptions
resource "google_pubsub_subscription" "collect_io_subscr1" {
  name = "collect_io_subscr1"
  topic = google_pubsub_topic.collect_io_topic.name
  # 20 minutes
  message_retention_duration = "1200s"
  retain_acked_messages      = true

  ack_deadline_seconds = 20

  retry_policy {
    minimum_backoff = "10s"
  }

  enable_message_ordering    = false

}

resource "google_pubsub_subscription" "collect_io_subscr2" {
  name = "collect_io_subscr2"
  topic = google_pubsub_topic.collect_io_topic.name

  retain_acked_messages = false

  ack_deadline_seconds = 10

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "40s"
  }

  dead_letter_policy {
    dead_letter_topic = google_pubsub_topic.err_collect_io_topic.id
    max_delivery_attempts = 10
  }
  enable_message_ordering = true
}

resource "google_pubsub_lite_topic" "collect-light-topic" {
  name = "collect-light-topic"

  partition_config {
    count = 4
    capacity {
      publish_mib_per_sec = 4
      subscribe_mib_per_sec = 8
    }
  }

  retention_config {
    per_partition_bytes = 32212254720
    peripd=1000
  }
}
