output "database_password" {
  value = random_password.db_password.result
}

output "database_connection" {
  value = google_sql_database_instance.main.connection_name
}

output "database_public_ip_address" {
  value = google_sql_database_instance.main.public_ip_address
}

output "database_user" {
  value = google_sql_user.keycloak.name
}
