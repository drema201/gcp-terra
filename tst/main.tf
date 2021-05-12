resource "google_service_account" "comp-acc" {
  account_id   = "composer-env-account"
  display_name = "Test Service Account for Composer Environment"
}

resource "google_service_account_key" "mykey" {
  service_account_id = google_service_account.comp-acc.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_member" "composer-worker" {
  role   = "roles/composer.worker"
  member = "serviceAccount:${google_service_account.comp-acc.email}"
}
resource "google_project_iam_member" "composer-worker-1" {
  role   = "roles/dataflow.developer"
  member = "serviceAccount:${google_service_account.comp-acc.email}"
}

resource "google_project_iam_member" "composer-worker-2" {
  role   = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.comp-acc.email}"
}

resource "google_project_iam_member" "composer-worker-3" {
  role   = "roles/bigquery.dataEditor"
  member = "serviceAccount:${google_service_account.comp-acc.email}"
}

resource "google_project_iam_member" "composer-worker-4" {
  role   = "roles/bigquery.jobUser"
  member = "serviceAccount:${google_service_account.comp-acc.email}"
}

resource "google_project_iam_member" "composer-worker-5" {
  role   = "roles/bigquery.user"
  member = "serviceAccount:${google_service_account.comp-acc.email}"
}
