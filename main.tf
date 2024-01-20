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

resource "google_compute_address" "static_address" {
  name   = "vm-static-ip"
  region = var.region
}

resource "google_compute_instance" "vm_instance" {
  name         = "example-instance"
  machine_type = "f1-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static_address.address
    }
  }
}