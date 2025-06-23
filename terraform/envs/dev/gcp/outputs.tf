output "project_id" {
  value = module.foundation.project_id
}

output "cluster_details" {
  value = module.cluster
}

output "database_details" {
  value     = module.postgresql
  sensitive = true
}

output "grafana_password" {
  description = "Grafana admin password"
  value       = random_password.grafana_password.result
  sensitive   = true
}

output "keycloak_password" {
  description = "Keycloak admin password"
  value       = random_password.keycloak_password.result
  sensitive   = true
}
