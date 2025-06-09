# =============================================================================
# PRODUCTION ENVIRONMENT VALUES - environments/prod/terraform.tfvars
# Enterprise-grade production configuration values
# =============================================================================

# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

# Replace with your actual production GCP project ID
project_id = "my-prod-project-67890"

# Multi-region setup for disaster recovery
region           = "us-central1"
secondary_region = "us-west1"

# Environment identifier
environment = "prod"

# =============================================================================
# NETWORKING CONFIGURATION (Production-grade ranges)
# =============================================================================

# VPC configuration (separate from dev)
vpc_name = "enterprise-vpc"

# Production subnet CIDR ranges (separate from dev/staging)
public_subnet_cidr  = "10.20.1.0/24"   # Production public subnet
private_subnet_cidr = "10.20.2.0/24"   # Production private subnet

# GKE secondary ranges (larger for production scale)
pod_cidr     = "10.21.0.0/16"   # Production pods (65k IPs)
service_cidr = "10.22.0.0/20"   # Production services (4k IPs)

# GKE master range
gke_master_cidr = "172.20.0.0/28"

# SSH access (RESTRICTED for production security)
ssh_source_ranges = [
  "203.0.113.0/24",   # Office network CIDR (replace with actual)
  "198.51.100.0/24"   # VPN network CIDR (replace with actual)
  # NEVER use "0.0.0.0/0" in production!
]

# =============================================================================
# GKE CLUSTER CONFIGURATION (High availability & performance)
# =============================================================================

gke_cluster_name = "enterprise-cluster"

# PRODUCTION HIGH-AVAILABILITY SETTINGS
gke_node_zones    = ["us-central1-a", "us-central1-b", "us-central1-c"]
gke_machine_type  = "e2-standard-4"    # 4 vCPU, 16GB RAM
gke_min_node_count = 1                 # Min per zone (3 total)
gke_max_node_count = 10                # Max per zone (30 total)
gke_disk_size_gb  = 100                # Production disk size
gke_disk_type     = "pd-ssd"           # SSD for performance

# Security settings
enable_private_endpoint = false  # Set to true for maximum security

# Authorized networks for GKE API access
master_authorized_networks = [
  {
    cidr_block   = "203.0.113.0/24"
    display_name = "Office Network"
  },
  {
    cidr_block   = "198.51.100.0/24"
    display_name = "VPN Network"
  },
  {
    cidr_block   = "10.20.0.0/16"
    display_name = "Production VPC"
  }
]

# High-memory node pool for data workloads
enable_high_memory_pool   = true
high_memory_machine_type  = "n2-highmem-4"  # 4 vCPU, 32GB RAM
high_memory_max_nodes     = 5

# Maintenance windows (controlled updates)
maintenance_start_time = "2024-01-01T02:00:00Z"  # 2 AM UTC Sunday
maintenance_end_time   = "2024-01-01T06:00:00Z"  # 6 AM UTC Sunday
maintenance_recurrence = "FREQ=WEEKLY;BYDAY=SU"

# =============================================================================
# CLOUDSQL CONFIGURATION (Enterprise database)
# =============================================================================

sql_instance_name = "enterprise-postgres"

# PRODUCTION DATABASE SETTINGS
sql_tier       = "db-custom-4-15360"  # 4 vCPU, 15GB RAM
sql_disk_size  = 500                  # 500GB for production
sql_disk_type  = "PD_SSD"             # SSD for performance

# Database and user names
sql_database_name = "production_app_db"
sql_app_user      = "production_app_user"

# Additional databases for microservices
additional_databases = [
  "analytics_db",
  "audit_db",
  "reporting_db",
  "user_management_db"
]

# =============================================================================
# BACKUP AND DISASTER RECOVERY
# =============================================================================

# Comprehensive backup strategy
backup_start_time     = "02:00"  # 2 AM for minimal impact
backup_retention_days = 30       # 30 days retention

# Database maintenance window
maintenance_window_day  = 7  # Sunday
maintenance_window_hour = 3  # 3 AM

# Read replicas for performance and DR
enable_read_replica = true
replica_region     = "us-west1"        # Different region for DR
replica_tier       = "db-custom-2-7680" # 2 vCPU, 7.5GB RAM

# =============================================================================
# MONITORING AND ALERTING
# =============================================================================

# Notification channels (replace with actual channel IDs)
notification_channels = [
  # "projects/my-prod-project-67890/notificationChannels/1234567890123456789",
  # "projects/my-prod-project-67890/notificationChannels/9876543210987654321"
  # Add your actual notification channel IDs here
]

# Database performance tuning flags
database_flags = [
  {
    name  = "max_connections"
    value = "200"
  },
  {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  },
  {
    name  = "effective_cache_size"
    value = "12GB"  # ~80% of available memory
  },
  {
    name  = "shared_buffers"
    value = "3840MB" # ~25% of available memory
  },
  {
    name  = "work_mem"
    value = "16MB"
  },
  {
    name  = "maintenance_work_mem"
    value = "512MB"
  },
  {
    name  = "log_statement"
    value = "all"
  },
  {
    name  = "log_duration"
    value = "on"
  },
  {
    name  = "log_lock_waits"
    value = "on"
  },
  {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries slower than 1 second
  }
]

# =============================================================================
# IAM AND SECURITY
# =============================================================================

# IAM users for database access
database_iam_users = {
  dba_team = {
    email           = "dba-team@yourcompany.com"
    deletion_policy = "ABANDON"
  },
  app_service_account = {
    email           = "app-prod@my-prod-project-67890.iam.gserviceaccount.com"
    deletion_policy = "DELETE"
  },
  monitoring_service_account = {
    email           = "monitoring-prod@my-prod-project-67890.iam.gserviceaccount.com"
    deletion_policy = "DELETE"
  }
}

# =============================================================================
# COMPLIANCE AND GOVERNANCE
# =============================================================================

# Compliance requirements
compliance_standards = [
  "SOC2",
  "PCI-DSS",
  "GDPR"
  # Add "HIPAA", "ISO27001" etc. as needed
]

data_classification    = "confidential"
retention_policy_years = 7

# Business continuity requirements
rto_hours = 4  # 4 hour recovery time objective
rpo_hours = 1  # 1 hour recovery point objective

# =============================================================================
# LABELS AND METADATA
# =============================================================================

common_labels = {
  managed-by          = "terraform"
  environment         = "prod"
  project            = "enterprise-platform"
  team               = "platform"
  purpose            = "production"
  tier               = "critical"
  backup-required    = "true"
  monitoring-required = "true"
  compliance-required = "true"
  data-classification = "confidential"
  disaster-recovery  = "enabled"
}

cost_center        = "production"
business_unit      = "platform"
owner             = "platform-team"
support_contact   = "platform-team@yourcompany.com"
escalation_contact = "cto@yourcompany.com"

# =============================================================================
# COST BREAKDOWN ESTIMATION (for reference)
# =============================================================================

# Expected monthly costs for this production setup:
# 
# GKE Cluster:
# - 3x e2-standard-4 nodes: ~$180-240/month
# - 5x n2-highmem-4 nodes (max): ~$500-600/month
# - 1TB total SSD storage: ~$170/month
# - GKE management fee: ~$73/month
# 
# CloudSQL:
# - Primary: db-custom-4-15360: ~$350/month
# - Read replica: db-custom-2-7680: ~$175/month
# - 500GB SSD storage x2: ~$170/month
# - Backup storage: ~$50/month
# 
# Networking:
# - Load balancers: ~$20/month
# - NAT Gateway: ~$50/month
# - Egress traffic: Variable
# 
# KMS:
# - Key operations: ~$10/month
# 
# Total estimated: $1,500-2,000/month
# (depending on actual usage and scaling)
# 
# COST OPTIMIZATION STRATEGIES:
# 1. Committed use discounts: Save 20-30%
# 2. Sustained use discounts: Automatic 20-30%
# 3. Resource optimization: Right-size based on monitoring
# 4. Archive old data: Reduce storage costs
# 5. Optimize networking: Minimize egress charges

# =============================================================================
# SECURITY CONFIGURATION NOTES
# =============================================================================

# PRODUCTION SECURITY FEATURES ENABLED:
# 
# Network Security:
# ✅ Private GKE nodes (no public IPs)
# ✅ Restricted SSH access (office/VPN only)
# ✅ Network policies for micro-segmentation
# ✅ VPC-native networking
# ✅ Private CloudSQL (no public IP)
# 
# Encryption:
# ✅ Customer-managed encryption keys (KMS)
# ✅ Database backup encryption
# ✅ Disk encryption (automatic)
# ✅ SSL/TLS for all database connections
# 
# Access Control:
# ✅ IAM-based database authentication
# ✅ Workload Identity for pods
# ✅ Service account key rotation
# ✅ Resource quotas and limits
# 
# Monitoring & Compliance:
# ✅ Comprehensive audit logging
# ✅ Performance monitoring
# ✅ Security alerting
# ✅ Backup monitoring
# 
# High Availability:
# ✅ Multi-zone deployment
# ✅ Regional database with replicas
# ✅ Automated backups with PITR
# ✅ Disaster recovery procedures

# =============================================================================
# DEPLOYMENT CHECKLIST
# =============================================================================

# BEFORE DEPLOYING TO PRODUCTION:
# 
# 1. ✅ Update all placeholder values:
#    - project_id
#    - ssh_source_ranges (your actual office/VPN IPs)
#    - notification_channels (your actual channel IDs)
#    - IAM user emails
#    - support contacts
# 
# 2. ✅ Security review:
#    - Verify SSH restrictions
#    - Confirm authorized networks
#    - Review IAM permissions
#    - Test backup/restore procedures
# 
# 3. ✅ Monitoring setup:
#    - Configure notification channels
#    - Set up alerting policies
#    - Test alert delivery
#    - Configure dashboards
# 
# 4. ✅ Compliance verification:
#    - Audit logging enabled
#    - Encryption configured
#    - Access controls in place
#    - Documentation updated
# 
# 5. ✅ Disaster recovery testing:
#    - Test backup restoration
#    - Verify replica failover
#    - Document recovery procedures
#    - Train support team