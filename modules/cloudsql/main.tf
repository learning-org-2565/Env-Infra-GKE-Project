# =============================================================================
# modules/cloudsql/main.tf
# =============================================================================

# Random Password Generation
resource "random_password" "postgres_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}"
}

resource "random_password" "app_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}"
}

# Private IP Configuration
resource "google_compute_global_address" "private_ip_range" {
  name          = "${var.project_id}-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.sql_private_range_prefix_length
  network       = var.vpc_network_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

# CloudSQL Instance
resource "google_sql_database_instance" "postgres" {
  name             = var.sql_instance_name
  database_version = var.sql_database_version
  region           = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = var.sql_tier

    disk_size       = var.sql_disk_size
    disk_type       = var.sql_disk_type
    disk_autoresize = var.sql_disk_autoresize

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_network_id
      #require_ssl     = true
    }

    backup_configuration {
      enabled                        = var.sql_backups_enabled
      start_time                     = var.sql_backup_start_time
      point_in_time_recovery_enabled = var.sql_point_in_time_recovery
      backup_retention_settings {
        retained_backups = var.sql_backup_retention_days
      }
    }

    # maintenance_window {
    #   day          = var.sql_maintenance_day
    #   hour         = var.sql_maintenance_hour
    #   update_track = "stable"
    # }

    # database_flags {
    #   name  = "max_connections"
    #   value = var.sql_max_connections
    # }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }
  }

  deletion_protection = var.sql_deletion_protection
}

# Database and Users
resource "google_sql_database" "database" {
  name      = var.sql_database_name
  instance  = google_sql_database_instance.postgres.name
  charset   = "UTF8"
  collation = "en_US.UTF8"
}

resource "google_sql_user" "postgres_user" {
  name     = "postgres"
  instance = google_sql_database_instance.postgres.name
  password = random_password.postgres_password.result
}

resource "google_sql_user" "app_user" {
  name     = var.sql_app_user
  instance = google_sql_database_instance.postgres.name
  password = random_password.app_password.result
}