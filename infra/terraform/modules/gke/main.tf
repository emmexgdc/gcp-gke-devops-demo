resource "google_container_cluster" "autopilot" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  enable_autopilot = true
  deletion_protection = false

  networking_mode = "VPC_NATIVE"

  release_channel {
    channel = "REGULAR"
  }
}