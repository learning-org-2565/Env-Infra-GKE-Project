# =============================================================================
# modules/cloudsql/outputs.tf
# =============================================================================

output "database_connection_info" {
  description = "CloudSQL instance connection information"
  value = {
    instance_name = google_sql_database_instance.postgres.name
    database_name = google_sql_database.database.name
    private_ip    = google_sql_database_instance.postgres.private_ip_address
  }
}

output "postgres_password" {
  description = "PostgreSQL admin user password"
  value       = random_password.postgres_password.result
  sensitive   = true
}

output "app_user_password" {
  description = "Application user password"
  value       = random_password.app_password.result
  sensitive   = true
}

output "database_connection_string" {
  description = "PostgreSQL connection string format"
  value       = "postgresql://${google_sql_user.app_user.name}:${random_password.app_password.result}@${google_sql_database_instance.postgres.private_ip_address}/${google_sql_database.database.name}"
  sensitive   = true
}

output "cloudsql_instance_id" {
  description = "The ID of the CloudSQL instance"
  value       = google_sql_database_instance.postgres.id
}

output "cloudsql_private_ip" {
  description = "The private IP address of the CloudSQL instance"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "connection_name" {
  description = "The connection name for CloudSQL proxy"
  value       = google_sql_database_instance.postgres.connection_name
}
