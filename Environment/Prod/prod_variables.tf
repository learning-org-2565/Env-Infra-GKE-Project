# =============================================================================
# PRODUCTION ENVIRONMENT VARIABLES - environments/prod/variables.tf
# Input variables for production environment (enterprise-grade)
# =============================================================================

# =============================================================================
# PROJECT AND ENVIRONMENT CONFIGURATION
# =============================================================================

variable "project_id" {
  description = "The GCP project ID for production environment"
  type        = string
  
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID cannot be empty."
  }
}

variable "region" {
  description = "The primary GCP region for production resources"
  type        = string
  default     = "us-central1"
  
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Region must be a valid GCP region format."
  }
}

variable "secondary_region" {
  description = "Secondary region for disaster recovery and read replicas"
  type        = string
  default     = "us-west1"
  
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.secondary_region))
    error_message = "Secondary region must be a valid GCP region format."
  }
}

variable "environment" {
  description = "Environment name (should be 'prod' for this configuration)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = var.environment == "prod"
    error_message = "This is the production environment configuration. Environment must be 'prod'."
  }
}

# =============================================================================
# VPC NETWORK CONFIGURATION (Production-grade)
# =============================================================================

variable "vpc_name" {
  description = "Base name for the VPC (will be prefixed with environment)"
  type        = string
  default     = "enterprise-vpc"
  
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.vpc_name))
    error_message = "VPC name must be lowercase letters, numbers, and hyphens only."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR range for the public subnet (load balancers, NAT)"
  type        = string
  default     = "10.20.1.0/24"  # Production-specific range
  
  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Public subnet CIDR must be a valid CIDR block."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR range for the private subnet (databases, internal services)"
  type        = string
  default     = "10.20.2.0/24"  # Production-specific range
  
  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "Private subnet CIDR must be a valid CIDR block."
  }
}

variable "pod_cidr" {
  description = "CIDR range for GKE pods (secondary range)"
  type        = string
  default     = "10.21.0.0/16"  # Production pod range (65k pods)
  
  validation {
    condition     = can(cidrhost(var.pod_cidr, 0))
    error_message = "Pod CIDR must be a valid CIDR block."
  }
}

variable "service_cidr" {
  description = "CIDR range for GKE services (secondary range)"
  type        = string
  default     = "10.22.0.0/20"  # Production service range (4k services)
  
  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "Service CIDR must be a valid CIDR block."
  }
}

variable "gke_master_cidr" {
  description = "CIDR range for GKE master nodes"
  type        = string
  default     = "172.20.0.0/28"  # Production master range
  
  validation {
    condition     = can(cidrhost(var.gke_master_cidr, 0))
    error_message = "GKE master CIDR must be a valid CIDR block."
  }
}

variable "ssh_source_ranges" {
  description = "CIDR ranges allowed to SSH (restricted for production)"
  type        = list(string)
  default = [
    "203.0.113.0/24",  # Office network example
    "198.51.100.0/24"  # VPN network example
  ]
  
  validation {
    condition = alltrue([
      for cidr in var.ssh_source_ranges : can(cidrhost(cidr, 0))
    ])
    error_message = "All SSH source ranges must be valid CIDR blocks."
  }
  
  validation {
    condition     = !contains(var.ssh_source_ranges, "0.0.0.0/0")
    error_message = "Production cannot allow SSH from anywhere (0.0.0.0/0). Specify office/VPN IP ranges."
  }
}

# =============================================================================
# GKE CLUSTER CONFIGURATION (Production-grade)
# =============================================================================

variable "gke_cluster_name" {
  description = "Base name for the GKE cluster (will be prefixed with environment)"
  type        = string
  default     = "enterprise-cluster"
  
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.gke_cluster_name))
    error_message = "Cluster name must be lowercase letters, numbers, and hyphens only."
  }
}

variable "gke_node_zones" {
  description = "List of zones for GKE nodes (multi-zone for HA)"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
  
  validation {
    condition     = length(var.gke_node_zones) >= 3
    error_message = "Production requires at least 3 zones for high availability."
  }
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes (production-sized)"
  type        = string
  default     = "e2-standard-4"  # 4 vCPU, 16GB RAM for production
  
  validation {
    condition = contains([
      "e2-standard-4", "e2-standard-8", "e2-standard-16",
      "n2-standard-4", "n2-standard-8", "n2-standard-16",
      "n2-highmem-4", "n2-highmem-8"
    ], var.gke_machine_type)
    error_message = "Production machine type must be suitable for production workloads."
  }
}

variable "gke_min_node_count" {
  description = "Minimum number of nodes per zone"
  type        = number
  default     = 1
  
  validation {
    condition     = var.gke_min_node_count >= 1
    error_message = "Production must have at least 1 node per zone."
  }
}

variable "gke_max_node_count" {
  description = "Maximum number of nodes per zone"
  type        = number
  default     = 10
  
  validation {
    condition     = var.gke_max_node_count >= var.gke_min_node_count
    error_message = "Maximum node count must be greater than or equal to minimum."
  }
}

variable "gke_disk_size_gb" {
  description = "Size of the disk attached to each GKE node (GB)"
  type        = number
  default     = 100  # Production disk size
  
  validation {
    condition     = var.gke_disk_size_gb >= 100
    error_message = "Production nodes should have at least 100GB disk."
  }
}

variable "gke_disk_type" {
  description = "Type of disk for GKE nodes"
  type        = string
  default     = "pd-ssd"  # SSD for production performance
  
  validation {
    condition     = var.gke_disk_type == "pd-ssd"
    error_message = "Production should use SSD disks for performance."
  }
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for GKE master (production security)"
  type        = bool
  default     = false  # Set to true for maximum security
}

variable "master_authorized_networks" {
  description = "Networks authorized to access GKE master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "203.0.113.0/24"
      display_name = "Office Network"
    },
    {
      cidr_block   = "198.51.100.0/24"
      display_name = "VPN Network"
    }
  ]
}

# =============================================================================
# HIGH-MEMORY NODE POOL (Production data workloads)
# =============================================================================

variable "enable_high_memory_pool" {
  description = "Enable high-memory node pool for data-intensive workloads"
  type        = bool
  default     = true
}

variable "high_memory_machine_type" {
  description = "Machine type for high-memory nodes"
  type        = string
  default     = "n2-highmem-4"  # 4 vCPU, 32GB RAM
  
  validation {
    condition = contains([
      "n2-highmem-2", "n2-highmem-4", "n2-highmem-8", "n2-highmem-16"
    ], var.high_memory_machine_type)
    error_message = "High memory machine type must be a valid high-memory instance."
  }
}

variable "high_memory_max_nodes" {
  description = "Maximum nodes in high-memory pool"
  type        = number
  default     = 5
  
  validation {
    condition     = var.high_memory_max_nodes >= 3
    error_message = "Production high-memory pool should allow at least 3 nodes."
  }
}

# =============================================================================
# MAINTENANCE WINDOWS
# =============================================================================

variable "maintenance_start_time" {
  description = "Maintenance window start time (RFC3339 format)"
  type        = string
  default     = "2024-01-01T02:00:00Z"  # 2 AM UTC
  
  validation {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", var.maintenance_start_time))
    error_message = "Maintenance start time must be in RFC3339 format."
  }
}

variable "maintenance_end_time" {
  description = "Maintenance window end time (RFC3339 format)"
  type        = string
  default     = "2024-01-01T06:00:00Z"  # 6 AM UTC
  
  validation {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", var.maintenance_end_time))
    error_message = "Maintenance end time must be in RFC3339 format."
  }
}

variable "maintenance_recurrence" {
  description = "Maintenance window recurrence (RFC5545 format)"
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SU"  # Every Sunday
}

# =============================================================================
# CLOUDSQL CONFIGURATION (Production-grade database)
# =============================================================================

variable "sql_instance_name" {
  description = "Base name for the CloudSQL instance (will be prefixed with environment)"
  type        = string
  default     = "enterprise-postgres"
  
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.sql_instance_name))
    error_message = "SQL instance name must be lowercase letters, numbers, and hyphens only."
  }
}

variable "sql_tier" {
  description = "Machine type for CloudSQL instance (production-sized)"
  type        = string
  default     = "db-custom-4-15360"  # 4 vCPU, 15GB RAM
  
  validation {
    condition = can(regex("^db-(custom-[4-9]-[0-9]+|custom-[1-9][0-9]+-[0-9]+)$", var.sql_tier))
    error_message = "Production SQL tier must be custom with at least 4 vCPU."
  }
}

variable "sql_disk_size" {
  description = "Disk size for CloudSQL instance (GB)"
  type        = number
  default     = 500  # Production database size
  
  validation {
    condition     = var.sql_disk_size >= 100
    error_message = "Production SQL disk should be at least 100GB."
  }
}

variable "sql_disk_type" {
  description = "Disk type for CloudSQL instance"
  type        = string
  default     = "PD_SSD"  # SSD for production performance
  
  validation {
    condition     = var.sql_disk_type == "PD_SSD"
    error_message = "Production should use SSD storage for performance."
  }
}

variable "sql_database_name" {
  description = "Name of the main database"
  type        = string
  default     = "production_app_db"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.sql_database_name))
    error_message = "Database name must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "sql_app_user" {
  description = "Name of the application database user"
  type        = string
  default     = "production_app_user"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.sql_app_user))
    error_message = "App user name must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "additional_databases" {
  description = "Additional databases for microservices"
  type        = list(string)
  default = [
    "analytics_db",
    "audit_db",
    "reporting_db"
  ]
}

# =============================================================================
# BACKUP AND DISASTER RECOVERY
# =============================================================================

variable "backup_start_time" {
  description = "Backup start time (HH:MM format)"
  type        = string
  default     = "02:00"  # 2 AM for minimal impact
  
  validation {
    condition     = can(regex("^[0-2][0-9]:[0-5][0-9]$", var.backup_start_time))
    error_message = "Backup start time must be in HH:MM format."
  }
}

variable "backup_retention_days" {
  description = "Number of automated backups to retain"
  type        = number
  default     = 30  # 30 days for production
  
  validation {
    condition     = var.backup_retention_days >= 30
    error_message = "Production should retain backups for at least 30 days."
  }
}

variable "maintenance_window_day" {
  description = "Day of week for database maintenance (1=Monday, 7=Sunday)"
  type        = number
  default     = 7  # Sunday
  
  validation {
    condition     = var.maintenance_window_day >= 1 && var.maintenance_window_day <= 7
    error_message = "Maintenance window day must be between 1 (Monday) and 7 (Sunday)."
  }
}

variable "maintenance_window_hour" {
  description = "Hour of day for database maintenance (0-23)"
  type        = number
  default     = 3  # 3 AM
  
  validation {
    condition     = var.maintenance_window_hour >= 0 && var.maintenance_window_hour <= 23
    error_message = "Maintenance window hour must be between 0 and 23."
  }
}

# =============================================================================
# READ REPLICAS (Production scaling)
# =============================================================================

variable "enable_read_replica" {
  description = "Enable read replica for production scaling"
  type        = bool
  default     = true
}

variable "replica_region" {
  description = "Region for read replica (disaster recovery)"
  type        = string
  default     = "us-west1"
  
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.replica_region))
    error_message = "Replica region must be a valid GCP region format."
  }
}

variable "replica_tier" {
  description = "Machine type for read replica"
  type        = string
  default     = "db-custom-2-7680"  # Smaller replica for read workloads
}

# =============================================================================
# MONITORING AND ALERTING
# =============================================================================

variable "notification_channels" {
  description = "Notification channels for production alerts"
  type        = list(string)
  default = [
    # "projects/PROJECT_ID/notificationChannels/CHANNEL_ID"
    # Add your actual notification channel IDs
  ]
}

variable "database_flags" {
  description = "Database flags for production performance tuning"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "max_connections"
      value = "200"
    },
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
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
    }
  ]
}

# =============================================================================
# IAM AND SECURITY
# =============================================================================

variable "database_iam_users" {
  description = "IAM users for database access"
  type = map(object({
    email           = string
    deletion_policy = string
  }))
  default = {
    dba_team = {
      email           = "dba-team@yourcompany.com"
      deletion_policy = "ABANDON"
    }
    app_service_account = {
      email           = "app-prod@your-project.iam.gserviceaccount.com"
      deletion_policy = "DELETE"
    }
  }
}

# =============================================================================
# COMPLIANCE AND GOVERNANCE
# =============================================================================

variable "compliance_standards" {
  description = "Compliance standards this environment must meet"
  type        = list(string)
  default = [
    "SOC2",
    "PCI-DSS",
    "GDPR",
    "HIPAA"  # Add as needed
  ]
}

variable "data_classification" {
  description = "Data classification level"
  type        = string
  default     = "confidential"
  
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "Data classification must be one of: public, internal, confidential, restricted."
  }
}

variable "retention_policy_years" {
  description = "Data retention policy in years"
  type        = number
  default     = 7
  
  validation {
    condition     = var.retention_policy_years >= 1
    error_message = "Retention policy must be at least 1 year."
  }
}

# =============================================================================
# BUSINESS CONTINUITY
# =============================================================================

variable "rto_hours" {
  description = "Recovery Time Objective in hours"
  type        = number
  default     = 4
  
  validation {
    condition     = var.rto_hours <= 24
    error_message = "RTO should be 24 hours or less for production."
  }
}

variable "rpo_hours" {
  description = "Recovery Point Objective in hours"
  type        = number
  default     = 1
  
  validation {
    condition     = var.rpo_hours <= 4
    error_message = "RPO should be 4 hours or less for production."
  }
}

# =============================================================================
# LABELS AND METADATA
# =============================================================================

variable "common_labels" {
  description = "Common labels to apply to all production resources"
  type        = map(string)
  default = {
    managed-by    = "terraform"
    project       = "enterprise-platform"
    team          = "platform"
    purpose       = "production"
    tier          = "critical"
    backup-required = "true"
    monitoring-required = "true"
  }
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = "production"
}

variable "business_unit" {
  description = "Business unit responsible for these resources"
  type        = string
  default     = "platform"
}

variable "owner" {
  description = "Owner of the production environment"
  type        = string
  default     = "platform-team"
}

variable "support_contact" {
  description = "Primary support contact for production issues"
  type        = string
  default     = "platform-team@yourcompany.com"
}

variable "escalation_contact" {
  description = "Escalation contact for critical production issues"
  type        = string
  default     = "cto@yourcompany.com"
}