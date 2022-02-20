resource "google_artifact_registry_repository" "click-repo" {
  provider = google-beta

  location = "us-central1"
  repository_id = "click-repo"
  description = "example docker repository for Click"
  format = "DOCKER"
}

resource "google_artifact_registry_repository_iam_binding" "binding" {
  provider = google-beta
  project = google_artifact_registry_repository.click-repo.project
  location = google_artifact_registry_repository.click-repo.location
  repository = google_artifact_registry_repository.click-repo.name
  role = "roles/viewer"
  members = [
    "serviceAccount:${google_service_account.gkecli.email}",
  ]
}