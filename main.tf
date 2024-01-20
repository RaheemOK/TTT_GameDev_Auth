provider "google" {
  credentials = file("top-the-tournament-409817-3ffd351a9474.json")
  project     = "top-the-tournament-409817"
  region      = "europe-west2"
}

resource "google_artifact_registry_repository" "my_repository" {
  provider = google
  location = "europe-west2"
  repository_id = "ttt-gamedev-auth-artifact-registry"
  format = "DOCKER"
}

