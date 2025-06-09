# =============================================================================
# modules/cloudsql/variables.tf
# =============================================================================

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "vpc_network_id" {
  description = "VPC network ID to connect CloudSQL to"
  type        = string
}

variable "sql_instance_name" {
  description = "Name for the CloudSQL instance"
  type        = string
  default     = "postgres-instance"
}

variable "sql_database_version" {
  description = "The database version to use"
  type        = string
  default     = "POSTGRES_14"
}

variable "sql_tier" {
  description = "The machine type to use"
  type        = string
  default     = "db-f1-micro"
}

variable "sql_disk_size" {
  description = "The size of the storage disk in GB"
  type        = number
  default     = 10
}

variable "sql_disk_type" {
  description = "The type of storage disk"
  type        = string
  default     = "PD_SSD"
}

variable "sql_disk_autoresize" {
  description = "Enable automatic storage increase"
  type        = bool
  default     = true
}

variable "sql_backups_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "sql_backup_start_time" {
  description = "Start time for backups in 24-hour format (HH:MM)"
  type        = string
  default     = "02:00"
}

variable "sql_point_in_time_recovery" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "sql_backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "sql_maintenance_day" {
  description = "Day of week for maintenance (1-7 for Monday-Sunday)"
  type        = number
  default     = 7
}

variable "sql_maintenance_hour" {
  description = "Hour for maintenance (0-23)"
  type        = number
  default     = 3
}

variable "sql_database_name" {
  description = "Name for the database"
  type        = string
  default     = "chatbot_db"
}

variable "sql_app_user" {
  description = "Username for the application"
  type        = string
  default     = "chatbot_app"
}

variable "sql_max_connections" {
  description = "Maximum allowed connections"
  type        = string
  default     = "100"
}

variable "sql_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "sql_private_range_prefix_length" {
  description = "Prefix length for the private IP range"
  type        = number
  default     = 16
}
