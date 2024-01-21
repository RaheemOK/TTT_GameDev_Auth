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

data "google_compute_address" "existing_static_address" {
  name   = "vm-static-ip"
  region = var.region
}

resource "google_compute_address" "static_address" {
  count  = length(data.google_compute_address.existing_static_address.*.id) > 0 ? 0 : 1
  name   = "vm-static-ip"
  region = var.region
}

data "google_compute_instance" "existing_vm" {
  name   = "ttt-gamedev-auth-micro-e2"
  zone   = var.zone
}

resource "google_compute_instance" "vm_instance" {
  count        = length(data.google_compute_instance.existing_vm.*.id) > 0 ? 0 : 1
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
      nat_ip = length(data.google_compute_address.existing_static_address.*.id) > 0 ? data.google_compute_address.existing_static_address.address : google_compute_address.static_address[0].address
    }
  }

  metadata = {
    "ssh-keys" = "raheem:${file("id_rsa_ttt_gda_micro.pub")}"
  }
}

output "vm_external_ip" {
  value = length(data.google_compute_address.existing_static_address.*.id) > 0 ? data.google_compute_address.existing_static_address.address : google_compute_address.static_address[0].address
}