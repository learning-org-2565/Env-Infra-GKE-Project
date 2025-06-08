# =============================================================================
# DEV ENVIRONMENT VARIABLES - environments/dev/variables.tf
# Input variables for development environment
# =============================================================================

# =============================================================================
# PROJECT AND ENVIRONMENT CONFIGURATION
# =============================================================================

variable "project_id" {
  description = "The GCP project ID for development environment"
  type        = string
  
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID cannot be empty."
  }
}

variable "region" {
  description = "The primary GCP region for dev resources"
  type        = string
  default     = "us-central1"
  
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Region must be a valid GCP region format."
  }
}

variable "primary_zone" {
  description = "The primary zone within the region (for single-zone dev deployments)"
  type        = string
  default     = "us-central1-a"
  
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]-[a-z]$", var.primary_zone))
    error_message = "Zone must be a valid GCP zone format."
  }
}

variable "environment" {
  description = "Environment name (should be 'dev' for this configuration)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = var.environment == "dev"
    error_message = "This is the dev environment configuration. Environment must be 'dev'."
  }
}

# =============================================================================
# VPC NETWORK CONFIGURATION (Dev-specific)
# =============================================================================

variable "vpc_name" {
  description = "Base name for the VPC (will be prefixed with environment)"
  type        = string
  default     = "devops-vpc"
  
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.vpc_name))
    error_message = "VPC name must be lowercase letters, numbers, and hyphens only."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR range for the public subnet (GKE nodes, load balancers)"
  type        = string
  default     = "10.10.1.0/24"  # Dev-specific range to avoid conflicts
  
  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Public subnet CIDR must be a valid CIDR block."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR range for the private subnet (CloudSQL, internal services)"
  type        = string
  default     = "10.10.2.0/24"  # Dev-specific range
  
  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "Private subnet CIDR must be a valid CIDR block."
  }
}

variable "pod_cidr" {
  description = "CIDR range for GKE pods (secondary range)"
  type        = string
  default     = "10.11.0.0/16"  # Dev-specific pod range
  
  validation {
    condition     = can(cidrhost(var.pod_cidr, 0))
    error_message = "Pod CIDR must be a valid CIDR block."
  }
}

variable "service_cidr" {
  description = "CIDR range for GKE services (secondary range)"
  type        = string
  default     = "10.12.0.0/20"  # Dev-specific service range
  
  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "Service CIDR must be a valid CIDR block."
  }
}

variable "gke_master_cidr" {
  description = "CIDR range for GKE master nodes"
  type        = string
  default     = "172.18.0.0/28"  # Dev-specific master range
  
  validation {
    condition     = can(cidrhost(var.gke_master_cidr, 0))
    error_message = "GKE master CIDR must be a valid CIDR block."
  }
}

variable "ssh_source_ranges" {
  description = "CIDR ranges allowed to SSH (broader for dev convenience)"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Open for dev - restrict in prod!
  
  validation {
    condition = alltrue([
      for cidr in var.ssh_source_ranges : can(cidrhost(cidr, 0))
    ])
    error_message = "All SSH source ranges must be valid CIDR blocks."
  }
}

# =============================================================================
# GKE CLUSTER CONFIGURATION (Dev-optimized)
# =============================================================================

variable "gke_cluster_name" {
  description = "Base name for the GKE cluster (will be prefixed with environment)"
  type        = string
  default     = "devops-cluster"
  
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.gke_cluster_name))
    error_message = "Cluster name must be lowercase letters, numbers, and hyphens only."
  }
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes (small for dev cost optimization)"
  type        = string
  default     = "e2-micro"  # Smallest for dev cost savings
  
  validation {
    condition = contains([
      "e2-micro", "e2-small", "e2-medium", "e2-standard-2"
    ], var.gke_machine_type)
    error_message = "Machine type must be a valid GCE machine type suitable for dev."
  }
}

variable "gke_node_count" {
  description = "Number of nodes in the GKE cluster (fixed for dev)"
  type        = number
  default     = 1  # Single node for dev cost savings
  
  validation {
    condition     = var.gke_node_count >= 1 && var.gke_node_count <= 3
    error_message = "Dev node count should be between 1 and 3 for cost optimization."
  }
}

variable "gke_disk_size_gb" {
  description = "Size of the disk attached to each GKE node (GB)"
  type        = number
  default     = 50  # Smaller disk for dev
  
  validation {
    condition     = var.gke_disk_size_gb >= 20 && var.gke_disk_size_gb <= 100
    error_message = "Dev disk size should be between 20 and 100 GB."
  }
}

variable "gke_disk_type" {
  description = "Type of disk for GKE nodes"
  type        = string
  default     = "pd-standard"  # Standard disk for cost savings
  
  validation {
    condition     = contains(["pd-standard", "pd-ssd"], var.gke_disk_type)
    error_message = "Disk type must be pd-standard or pd-ssd."
  }
}

# =============================================================================
# CLOUDSQL CONFIGURATION (Dev-optimized)
# =============================================================================

variable "sql_instance_name" {
  description = "Base name for the CloudSQL instance (will be prefixed with environment)"
  type        = string
  default     = "postgres-db"
  
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.sql_instance_name))
    error_message = "SQL instance name must be lowercase letters, numbers, and hyphens only."
  }
}

variable "sql_tier" {
  description = "Machine type for CloudSQL instance (small for dev)"
  type        = string
  default     = "db-f1-micro"  # Smallest tier for dev cost savings
  
  validation {
    condition = contains([
      "db-f1-micro", "db-g1-small", "db-n1-standard-1"
    ], var.sql_tier)
    error_message = "SQL tier must be appropriate for dev environment."
  }
}

variable "sql_disk_size" {
  description = "Disk size for CloudSQL instance (GB)"
  type        = number
  default     = 10  # Minimum size for dev
  
  validation {
    condition     = var.sql_disk_size >= 10 && var.sql_disk_size <= 50
    error_message = "Dev SQL disk size should be between 10 and 50 GB."
  }
}

variable "sql_disk_type" {
  description = "Disk type for CloudSQL instance"
  type        = string
  default     = "PD_SSD"  # SSD for better performance even in dev
  
  validation {
    condition     = contains(["PD_SSD", "PD_HDD"], var.sql_disk_type)
    error_message = "SQL disk type must be PD_SSD or PD_HDD."
  }
}

variable "sql_database_name" {
  description = "Name of the main database"
  type        = string
  default     = "dev_app_db"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.sql_database_name))
    error_message = "Database name must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "sql_app_user" {
  description = "Name of the application database user"
  type        = string
  default     = "dev_app_user"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.sql_app_user))
    error_message = "App user name must start with a letter and contain only letters, numbers, and underscores."
  }
}

# =============================================================================
# DEVELOPMENT-SPECIFIC FEATURES
# =============================================================================

variable "enable_dev_tools" {
  description = "Enable additional development tools and utilities"
  type        = bool
  default     = true
}

variable "create_dev_namespace" {
  description = "Create a dedicated development namespace in Kubernetes"
  type        = bool
  default     = true
}

variable "enable_debug_logging" {
  description = "Enable debug logging for development troubleshooting"
  type        = bool
  default     = true
}

variable "auto_delete_resources" {
  description = "Tag resources for automatic deletion (dev cleanup automation)"
  type        = bool
  default     = true
}

# =============================================================================
# COST OPTIMIZATION SETTINGS
# =============================================================================

variable "enable_cost_optimization" {
  description = "Enable aggressive cost optimization for development"
  type        = bool
  default     = true
}

variable "spot_instance_ratio" {
  description = "Percentage of nodes to run as spot instances (0.0 to 1.0)"
  type        = number
  default     = 1.0  # 100% spot instances for maximum dev cost savings
  
  validation {
    condition     = var.spot_instance_ratio >= 0.0 && var.spot_instance_ratio <= 1.0
    error_message = "Spot instance ratio must be between 0.0 and 1.0."
  }
}

variable "dev_shutdown_schedule" {
  description = "Cron schedule for shutting down dev resources during off-hours"
  type        = string
  default     = "0 18 * * 1-5"  # Shutdown at 6 PM on weekdays
  
  validation {
    condition     = can(regex("^[0-9*,/-]+ [0-9*,/-]+ [0-9*,/-]+ [0-9*,/-]+ [0-9*,/-]+$", var.dev_shutdown_schedule))
    error_message = "Shutdown schedule must be a valid cron expression."
  }
}

variable "dev_startup_schedule" {
  description = "Cron schedule for starting up dev resources during work hours"
  type        = string
  default     = "0 8 * * 1-5"  # Startup at 8 AM on weekdays
  
  validation {
    condition     = can(regex("^[0-9*,/-]+ [0-9*,/-]+ [0-9*,/-]+ [0-9*,/-]+ [0-9*,/-]+$", var.dev_startup_schedule))
    error_message = "Startup schedule must be a valid cron expression."
  }
}

# =============================================================================
# LABELS AND METADATA
# =============================================================================

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    managed-by    = "terraform"
    project       = "devops-learning"
    team          = "platform"
    purpose       = "development"
    auto-shutdown = "enabled"
  }
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = "development"
}

variable "owner" {
  description = "Owner of the development environment"
  type        = string
  default     = "platform-team"
}

variable "expiration_date" {
  description = "Expiration date for dev resources (YYYY-MM-DD format)"
  type        = string
  default     = "2024-12-31"
  
  validation {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", var.expiration_date))
    error_message = "Expiration date must be in YYYY-MM-DD format."
  }
}

# =============================================================================
# DEVELOPMENT WORKFLOW SETTINGS
# =============================================================================

variable "enable_hot_reload" {
  description = "Enable hot reload capabilities for faster development"
  type        = bool
  default     = true
}

variable "enable_debug_mode" {
  description = "Enable debug mode for applications"
  type        = bool
  default     = true
}

variable "log_level" {
  description = "Log level for development environment"
  type        = string
  default     = "DEBUG"
  
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARN, ERROR."
  }
}

# =============================================================================
# SECURITY SETTINGS (Relaxed for dev convenience)
# =============================================================================

variable "enable_dev_security_exceptions" {
  description = "Enable security exceptions for development convenience"
  type        = bool
  default     = true
}

variable "allow_insecure_connections" {
  description = "Allow insecure connections for easier development"
  type        = bool
  default     = true
}

variable "disable_ssl_verification" {
  description = "Disable SSL verification for development APIs"
  type        = bool
  default     = false  # Keep false for good practices
}

# =============================================================================
# MONITORING AND ALERTING (Simplified for dev)
# =============================================================================

variable "enable_basic_monitoring" {
  description = "Enable basic monitoring for development"
  type        = bool
  default     = true
}

variable "enable_dev_alerts" {
  description = "Enable development-specific alerts"
  type        = bool
  default     = false  # Disable alerts in dev to reduce noise
}

variable "metrics_retention_days" {
  description = "Number of days to retain metrics in development"
  type        = number
  default     = 7  # Short retention for cost savings
  
  validation {
    condition     = var.metrics_retention_days >= 1 && var.metrics_retention_days <= 30
    error_message = "Metrics retention must be between 1 and 30 days for dev."
  }
}