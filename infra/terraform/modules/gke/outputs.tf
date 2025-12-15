output "cluster_name" {
  value = google_container_cluster.autopilot.name
}

output "cluster_location" {
  value = google_container_cluster.autopilot.location
}

output "cluster_id" {
  value = google_container_cluster.autopilot.id
}