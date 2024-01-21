provider "google" {
  project = var.project
  region  = var.region
}

# Check if the address already exists
data "google_compute_address" "existing_static_address" {
  name   = "vm-static-ip"
  region = var.region
}

# Only create the address if it doesn't exist
resource "google_compute_address" "static_address" {
  count             = data.google_compute_address.existing_static_address ? 0 : 1
  name              = "vm-static-ip"
  region            = var.region
  address_type      = "EXTERNAL"
  purpose           = "VPC_PEERING"
  network_tier      = "PREMIUM"
  prefix_length     = 24
  address           = null
  project           = var.project
  terraform_labels  = {}
  effective_labels  = {}
  label_fingerprint = null
  users             = null
}

# Only create the instance if the address doesn't exist
resource "google_compute_instance" "vm_instance" {
  count = data.google_compute_address.existing_static_address ? 0 : 1

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
      nat_ip = try(lookup(google_compute_address.static_address[count.index], "address"), "")
    }
  }

  metadata = {
    "ssh-keys"       = "raheem:${file("id_rsa_ttt_gda_micro.pub")}"
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

# Output the external IP address if it was created
output "vm_external_ip" {
  value = google_compute_address.static_address[0].address
}
