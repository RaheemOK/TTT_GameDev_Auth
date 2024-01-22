terraform {
  backend "gcs" {
    bucket = "ttt_terrabucket"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_artifact_registry_repository" "my_repository" {
  provider     = google
  location     = var.region
  repository_id = var.repository_id
  format       = "DOCKER"
}

resource "google_compute_address" "static_address" {
  name   = "vm-static-ip"
  region = var.region
}

resource "google_compute_instance" "vm_instance" {
  name         = "ttt-gamedev-auth-micro-e2"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-10"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static_address.address
    }
  }

  metadata = {
    "ssh-keys" = "raheem:${file("id_rsa_ttt_gda_micro.pub")}"
    "startup-script" = <<-EOT
      #!/bin/bash
      apt-get update
      apt-get install -y docker.io
      usermod -aG docker raheem
    EOT
  }
}

# Service Account Creation
resource "google_service_account" "artifact_service_account" {
  account_id   = "artifact-admin-sa"
  display_name = "Artifact Registry Admin Service Account"
}

# Service Account Key Generation
resource "google_service_account_key" "artifact_service_account_key" {
  service_account_id = google_service_account.artifact_service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# Assigning Role
resource "google_project_iam_member" "artifact_sa_role" {
  project = var.project
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.artifact_service_account.email}"
}

# Output the IP address
output "vm_external_ip" {
  value = google_compute_address.static_address.address
}


output "artifact_registry_service_account_key" {
  value = {
    key = google_service_account_key.artifact_service_account_key.private_key
  }
  sensitive = true
}