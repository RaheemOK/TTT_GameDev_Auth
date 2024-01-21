provider "google" {
  project = var.project
  region  = var.region
}

# Check if the Artifact Registry repository exists
resource "google_artifact_registry_repository" "my_repository" {
  provider     = google
  location     = var.region
  repository_id = var.repository_id
  format       = "DOCKER"
}

# Create the static IP address if it does not exist
resource "google_compute_address" "static_address" {
  name   = "vm-static-ip"
  region = var.region
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      address
    ]
  }
}

# Create the VM instance if it does not exist
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
  }
}

output "vm_external_ip" {
  value = google_compute_address.static_address.address
}