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

# Attempt to fetch existing static IP address, create new if not found
resource "google_compute_address" "static_address" {
  name   = "vm-static-ip"
  region = var.region

  # Use count to create the address only if it doesn't exist
  count = length(data.google_compute_address.existing_static_address) == 0 ? 1 : 0

  lifecycle {
    create_before_destroy = true
  }
}

# Attempt to fetch existing VM, create new if not found
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
      nat_ip = try(lookup(google_compute_address.static_address, "address", ""), "")
    }
  }

  metadata = {
    "ssh-keys" = "raheem:${file("id_rsa_ttt_gda_micro.pub")}"
    "startup-script" = <<-EOT
      #!/bin/bash
      apt-get update
      apt-get install -y docker.io
    EOT
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "vm_external_ip" {
  value = data.google_compute_address.existing_static_address != null ? data.google_compute_address.existing_static_address[0].address : google_compute_address.static_address[0].address
}

data "google_compute_address" "existing_static_address" {
  name   = "vm-static-ip"
  region = var.region
}
