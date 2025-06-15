resource "random_password" "db_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "google_sql_database_instance" "main" {
  name             = "${var.project_name}-sql"
  project          = var.project_id
  database_version = "POSTGRES_15"

  settings {
    tier      = "db-f1-micro"
    disk_size = 10

    ip_configuration {
      ipv4_enabled = true

      authorized_networks {
        name  = "gke-cluster"
        value = "0.0.0.0/0" # Or restrict to your GKE cluster CIDR
      }
    }

    backup_configuration {
      enabled = false
    }

    disk_autoresize = true
  }

  deletion_protection = false
}

resource "google_sql_user" "keycloak" {
  name     = "admin"
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result

  deletion_policy = "ABANDON"

  depends_on = [google_sql_database_instance.main]
}
