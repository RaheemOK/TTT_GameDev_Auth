provider "google" {
  project = var.project
  region  = var.region
}

# Check if the Artifact Registry repository exists
data "google_artifact_registry_repository" "existing_repository" {
  count         = terraform.workspace == "default" ? 0 : 1
  provider      = google
  location      = var.region
  repository_id = var.repository_id
}

# Create the Artifact Registry repository if it does not exist
resource "google_artifact_registry_repository" "my_repository" {
  count         = length(data.google_artifact_registry_repository.existing_repository.*.id) == 0 ? 1 : 0
  provider      = google
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
}

# Attempt to read existing static IP
data "google_compute_address" "existing_static_address" {
  count  = "vm-static-ip"
  name   = "vm-static-ip"
  region = var.region
}

# Create the static IP if it does not exist
resource "google_compute_address" "static_address" {
  count  = length(data.google_compute_address.existing_static_address.*.id) == 0 ? 1 : 0
  name   = "vm-static-ip"
  region = var.region
}

# Check if the VM instance exists
data "google_compute_instance" "existing_vm" {
  count  = terraform.workspace == "default" ? 0 : 1
  name   = "ttt-gamedev-auth-micro-e2"
  zone   = var.zone
  project = var.project
}

# Create the VM instance if it does not exist
resource "google_compute_instance" "vm_instance" {
  count        = length(data.google_compute_instance.existing_vm.*.id) == 0 ? 1 : 0
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
      nat_ip = length(data.google_compute_address.existing_static_address.*.id) > 0 ? data.google_compute_address.existing_static_address[0].address : google_compute_address.static_address[0].address
    }
  }

  metadata = {
    "ssh-keys" = "raheem:${file("id_rsa_ttt_gda_micro.pub")}"
  }
}

output "vm_external_ip" {
  value = length(data.google_compute_address.existing_static_address.*.id) > 0 ? data.google_compute_address.existing_static_address[0].address : google_compute_address.static_address[0].address
}
