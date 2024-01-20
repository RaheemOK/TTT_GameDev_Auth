provider "google" {
  project = var.project
  region  = var.region
}

resource "google_artifact_registry_repository" "my_repository" {
  provider = google
  location = var.region
  repository_id = var.repository_id
  format = "DOCKER"
}

