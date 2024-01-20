provider "google" {
  project = var.project
  region  = var.region
}

resource "google_artifact_registry_repository" "my_repository" {
  provider = google
  location = "europe-west2"
  repository_id = "ttt-gamedev-auth-artifact-registry"
  format = "DOCKER"
}

