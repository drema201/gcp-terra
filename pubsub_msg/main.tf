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
  name = "collect_io_topic-topic"

  depends_on = [google_pubsub_schema.collect_io_sch]
  schema_settings {
    schema = "projects/postgretrial/schemas/collect_io_sch"
    encoding = "JSON"
  }
}
