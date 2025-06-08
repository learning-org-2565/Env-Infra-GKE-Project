# =============================================================================
# main.tf (Root) - Updated with CloudSQL for Dev Environment
# =============================================================================

locals {
  vpc_name = "${var.environment}-devops-vpc"
  gke_name = "${var.environment}-devops-gke"

  common_labels = {
    environment = var.environment
    project     = "devops-learning"
    created_by  = "terraform"
  }

  # CloudSQL is only deployed in dev environment
  deploy_cloudsql = var.environment == "dev"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_id          = var.project_id
  region              = var.region
  vpc_name            = local.vpc_name
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  pod_cidr            = "10.1.0.0/16"
  service_cidr        = "10.2.0.0/20"
  enable_nat_gateway  = true
  enable_flow_logs    = false
  labels              = local.common_labels
}

# GKE Module
module "gke" {
  source = "./modules/gke"

  project_id       = var.project_id
  region           = var.region
  gke_cluster_name = local.gke_name
  environment      = var.environment

  # Use existing service account
  service_account_email = "githubactions-sa@turnkey-guild-441104-f3.iam.gserviceaccount.com"

  # Ensure minimum 3 zones for storage quota distribution
  node_zones = [
    "${var.region}-a",
    "${var.region}-c"
  ]

  # Use VPC module outputs
  vpc_network        = module.vpc.vpc_self_link
  vpc_subnetwork     = module.vpc.public_subnet_id
  pod_range_name     = "pod-range"
  service_range_name = "service-range"

  # Node configuration
  gke_num_nodes    = var.gke_num_nodes
  gke_min_nodes    = var.gke_min_nodes
  gke_max_nodes    = var.gke_max_nodes
  gke_machine_type = var.gke_machine_type
  gke_disk_size_gb = var.gke_disk_size_gb

  # Security settings
  enable_network_policy = true
  enable_shielded_nodes = true

  labels = local.common_labels

  depends_on = [module.vpc]
}

# CloudSQL Module - Only for dev environment
module "cloudsql" {
  count = local.deploy_cloudsql ? 1 : 0

  source = "./modules/cloudsql"

  project_id     = var.project_id
  region         = var.region
  vpc_network_id = module.vpc.vpc_id

  # CloudSQL configuration
  sql_instance_name               = var.sql_instance_name
  sql_database_version            = var.sql_database_version
  sql_tier                        = var.sql_tier
  sql_disk_size                   = var.sql_disk_size
  sql_disk_type                   = var.sql_disk_type
  sql_disk_autoresize             = var.sql_disk_autoresize
  sql_backups_enabled             = var.sql_backups_enabled
  sql_backup_start_time           = var.sql_backup_start_time
  sql_point_in_time_recovery      = var.sql_point_in_time_recovery
  sql_backup_retention_days       = var.sql_backup_retention_days
  sql_database_name               = var.sql_database_name
  sql_app_user                    = var.sql_app_user
  sql_deletion_protection         = var.sql_deletion_protection
  sql_private_range_prefix_length = var.sql_private_range_prefix_length

  depends_on = [module.vpc]
}