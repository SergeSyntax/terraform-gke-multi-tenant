# gcloud container clusters get-credentials "${google_container_cluster.gke.name}" --location=${google_container_cluster.gke.location} --project=${var.project_id}"


output "name" {
  value = google_container_cluster.gke.name
}

output "location" {
  value = google_container_cluster.gke.location
}
