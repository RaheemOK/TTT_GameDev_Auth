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

# Check if the static IP exists
data "google_compute_address" "existing_static_address" {
  name   = "vm-static-ip"
  region = var.region
}

# Create static IP if it doesn't exist
resource "google_compute_address" "static_address" {
  count  = data.google_compute_address.existing_static_address.id == "" ? 1 : 0
  name   = "vm-static-ip"
  region = var.region
}

# Check if the VM exists
data "google_compute_instance" "existing_vm" {
  name   = "ttt-gamedev-auth-micro-e2"
  zone   = var.zone
}

# Create VM if it doesn't exist
resource "google_compute_instance" "vm_instance" {
  count        = data.google_compute_instance.existing_vm.id == "" ? 1 : 0
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
      nat_ip = data.google_compute_address.existing_static_address.id != "" ? data.google_compute_address.existing_static_address.address : google_compute_address.static_address[0].address
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
}

output "vm_external_ip" {
  value = data.google_compute_address.existing_static_address.id != "" ? data.google_compute_address.existing_static_address.address : google_compute_address.static_address[0].address
}
