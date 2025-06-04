# =============================================================================
# DEV ENVIRONMENT VALUES - environments/dev/terraform.tfvars
# Specific values for development environment
# =============================================================================

# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

# Replace with your actual GCP project ID
project_id = "my-dev-project-12345"

# Primary region and zone for dev (single region for cost)
region       = "us-central1"
primary_zone = "us-central1-a"

# Environment identifier
environment = "dev"

# =============================================================================
# NETWORKING CONFIGURATION (Dev-specific ranges)
# =============================================================================

# VPC configuration
vpc_name = "dev-vpc"

# Subnet CIDR ranges (dev-specific to avoid conflicts with prod)
public_subnet_cidr  = "10.10.1.0/24"   # Dev public subnet
private_subnet_cidr = "10.10.2.0/24"   # Dev private subnet

# GKE secondary ranges
pod_cidr     = "10.11.0.0/16"   # Dev pods (65k IPs)
service_cidr = "10.12.0.0/20"   # Dev services (4k IPs)

# GKE master range
gke_master_cidr = "172.18.0.0/28"

# SSH access (open for dev convenience - restrict for prod!)
ssh_source_ranges = [
  "0.0.0.0/0"  # Allow from anywhere in dev
  # In real scenarios, use your office/home IP:
  # "203.0.113.0/24"  # Your office network
]

# =============================================================================
# GKE CLUSTER CONFIGURATION (Small & cheap for dev)
# =============================================================================

gke_cluster_name = "dev-cluster"

# COST-OPTIMIZED SETTINGS FOR DEV
gke_machine_type  = "e2-micro"      # Smallest machine type
gke_node_count    = 1               # Single node for cost
gke_disk_size_gb  = 50              # Small disk
gke_disk_type     = "pd-standard"   # Standard disk (cheaper)

# =============================================================================
# CLOUDSQL CONFIGURATION (Minimal for dev)
# =============================================================================

sql_instance_name = "dev-postgres"

# COST-OPTIMIZED DATABASE SETTINGS
sql_tier       = "db-f1-micro"   # Smallest CloudSQL instance
sql_disk_size  = 10              # Minimum disk size
sql_disk_type  = "PD_SSD"        # SSD for better performance

# Database and user names
sql_database_name = "dev_app_db"
sql_app_user      = "dev_app_user"

# =============================================================================
# DEVELOPMENT FEATURES
# =============================================================================

# Enable dev-specific features
enable_dev_tools       = true
create_dev_namespace   = true
enable_debug_logging   = true
auto_delete_resources  = true

# Cost optimization
enable_cost_optimization = true
spot_instance_ratio     = 1.0  # 100% spot instances for max savings

# Development schedules (optional - for advanced cost optimization)
dev_shutdown_schedule = "0 18 * * 1-5"  # 6 PM weekdays
dev_startup_schedule  = "0 8 * * 1-5"   # 8 AM weekdays

# =============================================================================
# DEVELOPMENT WORKFLOW
# =============================================================================

# Development features
enable_hot_reload = true
enable_debug_mode = true
log_level        = "DEBUG"

# Security (relaxed for dev convenience)
enable_dev_security_exceptions = true
allow_insecure_connections     = true
disable_ssl_verification       = false  # Keep secure practices

# =============================================================================
# MONITORING (Simplified for dev)
# =============================================================================

enable_basic_monitoring = true
enable_dev_alerts       = false  # No alerts in dev
metrics_retention_days  = 7      # Short retention

# =============================================================================
# LABELS AND METADATA
# =============================================================================

common_labels = {
  managed-by     = "terraform"
  environment    = "dev"
  project        = "devops-learning"
  team           = "platform"
  purpose        = "development"
  auto-shutdown  = "enabled"
  cost-optimized = "true"
}

cost_center     = "development"
owner          = "platform-team"
expiration_date = "2024-12-31"

# =============================================================================
# COST BREAKDOWN ESTIMATION (for reference)
# =============================================================================

# Expected monthly costs for this dev setup:
# 
# GKE:
# - 1x e2-micro node (preemptible): ~$3-5/month
# - 50GB pd-standard disk: ~$2/month
# - GKE management fee: ~$0 (free tier)
# 
# CloudSQL:
# - db-f1-micro instance: ~$7/month
# - 10GB SSD storage: ~$1.70/month
# 
# Networking:
# - VPC, subnets, firewall rules: Free
# - NAT Gateway: ~$45/month (if used heavily)
# - External IP: ~$1.46/month
# 
# Total estimated: ~$15-60/month
# (depending on usage patterns and NAT Gateway usage)
# 
# COST OPTIMIZATION TIPS:
# 1. Use spot instances (enabled): Save 60-80%
# 2. Auto-shutdown schedule (optional): Save ~70% on compute
# 3. Delete when not needed: Save 100%
# 4. Monitor with billing alerts

# =============================================================================
# SECURITY NOTES FOR LEARNING
# =============================================================================

# IMPORTANT: This is a DEVELOPMENT configuration with relaxed security:
# 
# 1. SSH access from 0.0.0.0/0 (anywhere)
# 2. GKE public nodes and endpoints
# 3. Relaxed firewall rules
# 4. No SSL requirements for CloudSQL
# 5. Debug logging enabled
# 
# FOR PRODUCTION:
# - Restrict SSH to specific IP ranges
# - Use private GKE nodes and endpoints
# - Enable SSL for all database connections
# - Implement strict firewall rules
# - Enable audit logging
# - Use customer-managed encryption keys