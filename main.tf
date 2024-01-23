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
  provider      = google
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
}

resource "google_compute_address" "static_address" {
  name   = "vm-static-ip"
  region = var.region
}

resource "google_compute_firewall" "allow-8080" {
  name    = "allow-8080"
  network = "default"  # You can change the network name if needed
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = ["0.0.0.0/0"]  # You can restrict the source IP range if needed
  target_tags   = ["allow-8080"]  # Match the tag from the instance
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

  tags = ["allow-8080"]  # Add the tag for the firewall rule here

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

resource "google_service_account" "artifact_service_account" {
  account_id   = "artifact-admin-sa"
  display_name = "Artifact Registry Admin Service Account"
}

resource "google_service_account_key" "artifact_service_account_key" {
  service_account_id = google_service_account.artifact_service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_member" "artifact_sa_role" {
  project = var.project
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.artifact_service_account.email}"
}

resource "google_storage_bucket" "secrets_bucket" {
  name          = "ttt-secrets-bucket"
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket_iam_binding" "binding" {
  bucket = google_storage_bucket.secrets_bucket.name
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.artifact_service_account.email}",
  ]
}

resource "google_storage_bucket_object" "vm_ip" {
  name    = "secrets/vm_external_ip.txt"
  bucket  = google_storage_bucket.secrets_bucket.name
  content = google_compute_address.static_address.address
}

resource "google_storage_bucket_object" "service_account_key" {
  name    = "secrets/artifact_registry_service_account_key.json"
  bucket  = google_storage_bucket.secrets_bucket.name
  content = google_service_account_key.artifact_service_account_key.private_key
}
