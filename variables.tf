variable "project" {
  description = "The GCP project ID"
}

variable "region" {
  description = "The GCP region"
  default     = "europe-west2"
}

variable "repository_id" {
  description = "The Artifact Registry repository ID"
}

variable "zone" {
  description = "The GCP zone"
  default     = "europe-west2-a"
}

