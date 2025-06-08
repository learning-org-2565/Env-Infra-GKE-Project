# =============================================================================
# dev.tfvars
# =============================================================================

project_id      = "turnkey-guild-441104-f3"
region          = "us-central1"
zone            = "us-central1-a"
environment     = "dev"

# GKE Configuration
gke_num_nodes   = 1
gke_min_nodes   = 1
gke_max_nodes   = 3
gke_machine_type = "e2-medium"
gke_disk_size_gb = 100

# CloudSQL Configuration
sql_instance_name     = "chatbot-postgres-dev"
sql_database_version  = "POSTGRES_14"
sql_tier             = "db-f1-micro"
sql_disk_size        = 20
sql_database_name    = "chatbot_db"
sql_app_user         = "chatbot_app"
sql_deletion_protection = false
sql_backup_retention_days = 3