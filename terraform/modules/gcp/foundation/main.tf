resource "random_id" "project" {
  byte_length = 1
}

locals {
  project_id = "${var.project_name}-${random_id.project.hex}"
  apis = [
    "compute.googleapis.com",   # for vm management
    "container.googleapis.com", # for GKE
    "logging.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

resource "google_project" "main" {
  name            = var.project_name
  project_id      = local.project_id
  billing_account = var.billing_account

  auto_create_network = false
  deletion_policy     = var.deletion_policy
}

resource "google_project_service" "api" {
  for_each = toset(local.apis)

  project            = google_project.main.project_id
  service            = each.key
  disable_on_destroy = false

  depends_on = [google_project.main]
}
