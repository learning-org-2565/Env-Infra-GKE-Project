# =============================================================================
# PRODUCTION ENVIRONMENT - environments/prod/main.tf
# Enterprise-grade production infrastructure using our custom modules
# =============================================================================

# =============================================================================
# TERRAFORM AND PROVIDER CONFIGURATION
# =============================================================================

terraform {
  required_version = ">= 1.0"

  # Backend configuration for production state isolation
  backend "gcs" {
    # Configuration loaded from backend-config file during init
    # terraform init -backend-config=backend-prod.tfbackend
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Configure Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Configure Google Beta Provider for advanced features
provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Data source for Google Client Config (for Kubernetes auth)
data "google_client_config" "default" {}

# =============================================================================
# KMS KEY RING AND KEYS (Production Security)
# =============================================================================

# Create KMS key ring for production encryption
resource "google_kms_key_ring" "prod_keyring" {
  name     = "${var.environment}-encryption-keyring"
  location = var.region
  project  = var.project_id
}

# GKE database encryption key
resource "google_kms_crypto_key" "gke_database_key" {
  name     = "${var.environment}-gke-database-key"
  key_ring = google_kms_key_ring.prod_keyring.id
  purpose  = "ENCRYPT_DECRYPT"

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  # Rotate keys every 90 days for security
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

# CloudSQL backup encryption key
resource "google_kms_crypto_key" "cloudsql_backup_key" {
  name     = "${var.environment}-cloudsql-backup-key"
  key_ring = google_kms_key_ring.prod_keyring.id
  purpose  = "ENCRYPT_DECRYPT"

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# MODULE 1: VPC NETWORK (Production-grade networking)
# =============================================================================

module "vpc" {
  # Use versioned module for production stability
  source = "git::https://github.com/yourorg/terraform-modules.git//vpc?ref=v1.0.0"
  
  # Local development alternative
  # source = "../../modules/vpc"

  # Required variables
  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  # Production VPC configuration
  vpc_name             = "${var.environment}-${var.vpc_name}"
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  pod_cidr            = var.pod_cidr
  service_cidr        = var.service_cidr

  # Production security settings (restricted access)
  ssh_source_ranges = var.ssh_source_ranges  # Office IP ranges only
  gke_master_cidr   = var.gke_master_cidr

  # Production-specific labels
  labels = merge(var.common_labels, {
    environment     = var.environment
    cost-center     = "production"
    compliance      = "required"
    data-classification = "confidential"
    backup-required = "true"
  })

  # Production networking options
  enable_flow_logs        = true   # Full logging for security
  flow_log_sampling       = 1.0    # 100% sampling for compliance
  enable_private_google_access = true
  nat_min_ports_per_vm    = 128     # Higher ports for production traffic
  nat_log_filter         = "ALL"   # Comprehensive NAT logging
}

# =============================================================================
# MODULE 2: GKE CLUSTER (Production-grade Kubernetes)
# =============================================================================

module "gke" {
  # Use versioned module for production stability
  source = "git::https://github.com/yourorg/terraform-modules.git//gke?ref=v1.0.0"
  
  # Local development alternative
  # source = "../../modules/gke"

  # Required variables
  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  # Cluster configuration
  cluster_name = "${var.environment}-${var.gke_cluster_name}"

  # Network configuration from VPC module
  network           = module.vpc.gke_network_config.network
  subnetwork        = module.vpc.gke_network_config.subnetwork
  pod_range_name    = module.vpc.gke_network_config.pod_range_name
  service_range_name = module.vpc.gke_network_config.service_range_name

  # PRODUCTION SETTINGS (Large, resilient, multi-zone)
  node_zones        = var.gke_node_zones  # Multi-zone for HA
  machine_type      = var.gke_machine_type
  disk_size_gb      = var.gke_disk_size_gb
  disk_type         = var.gke_disk_type

  # High availability and scaling
  enable_autoscaling    = true
  min_node_count       = var.gke_min_node_count
  max_node_count       = var.gke_max_node_count
  auto_repair          = true
  auto_upgrade         = true

  # Production security settings (hardened)
  enable_private_nodes    = true   # Private nodes for security
  enable_private_endpoint = var.enable_private_endpoint
  master_ipv4_cidr_block  = var.gke_master_cidr

  # Restricted access for production
  master_authorized_networks = var.master_authorized_networks

  # Production features
  enable_dns_cache = true
  
  # Database encryption with customer-managed keys
  database_encryption_key = google_kms_crypto_key.gke_database_key.id

  # Maintenance window for controlled updates
  maintenance_start_time = var.maintenance_start_time
  maintenance_end_time   = var.maintenance_end_time
  maintenance_recurrence = var.maintenance_recurrence

  # High-memory node pool for data workloads
  enable_high_memory_pool   = var.enable_high_memory_pool
  high_memory_machine_type  = var.high_memory_machine_type
  high_memory_max_nodes     = var.high_memory_max_nodes

  # Production security features
  enable_spot_instances = false  # No spot instances in prod
  
  # Labels for cost tracking and compliance
  labels = merge(var.common_labels, {
    environment     = var.environment
    cluster-size    = "large"
    cost-type      = "production"
    sla-tier       = "critical"
    backup-required = "true"
  })

  node_labels = {
    environment = var.environment
    node-type   = "production"
    cost-center = "production"
    sla-tier    = "critical"
  }

  network_tags = ["web", "prod", "critical"]

  # Workload Identity service accounts
  workload_identity_service_accounts = [
    {
      name      = "backend-sa"
      namespace = "production"
    },
    {
      name      = "monitoring-sa"
      namespace = "monitoring"
    }
  ]

  # Additional service account roles for production
  additional_service_account_roles = [
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
    "roles/cloudtrace.agent"
  ]

  # Depends on VPC and KMS keys being ready
  depends_on = [
    module.vpc,
    google_kms_crypto_key.gke_database_key
  ]
}

# =============================================================================
# MODULE 3: CLOUDSQL DATABASE (Production-grade database)
# =============================================================================

module "cloudsql" {
  # Use versioned module for production stability
  source = "git::https://github.com/yourorg/terraform-modules.git//cloudsql?ref=v1.0.0"
  
  # Local development alternative
  # source = "../../modules/cloudsql"

  # Required variables
  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  # Instance configuration
  instance_name = "${var.environment}-${var.sql_instance_name}"

  # Network configuration from VPC module
  network_id        = module.vpc.vpc_id
  network_name      = module.vpc.vpc_name
  network_self_link = module.vpc.vpc_self_link

  # PRODUCTION SETTINGS (Large, resilient, comprehensive features)
  tier              = var.sql_tier
  disk_size_gb      = var.sql_disk_size
  disk_type         = var.sql_disk_type
  availability_type = "REGIONAL"  # High availability

  # Database configuration
  database_name     = var.sql_database_name
  app_user_name     = var.sql_app_user
  additional_databases = var.additional_databases

  # PRODUCTION BACKUP SETTINGS (Comprehensive)
  backup_enabled                 = true
  backup_start_time             = var.backup_start_time
  point_in_time_recovery_enabled = true
  backup_retained_backups       = var.backup_retention_days
  transaction_log_retention_days = 7

  # Security settings (hardened for production)
  require_ssl                    = true
  enable_public_ip              = false  # Private networking only
  deletion_protection           = true   # Prevent accidental deletion

  # Advanced security features
  enable_iam_auth                     = true
  enable_backup_encryption            = true
  store_passwords_in_secret_manager   = true
  enable_password_rotation            = true
  password_rotation_days              = 90

  # Production maintenance window
  maintenance_window_day  = var.maintenance_window_day
  maintenance_window_hour = var.maintenance_window_hour

  # SSL certificates for secure connections
  create_ssl_cert     = true
  create_app_ssl_cert = true

  # Read replicas for performance and disaster recovery
  enable_read_replica    = var.enable_read_replica
  replica_region        = var.replica_region
  replica_tier          = var.replica_tier
  replica_failover_target = true

  # Network access (restricted to authorized sources)
  allowed_source_ranges = [
    module.vpc.pod_cidr,
    module.vpc.service_cidr,
    module.vpc.network_config.private_subnet_cidr
  ]

  # Advanced monitoring and alerting
  enable_uptime_checks = true
  enable_alerting     = true
  enable_audit_logs   = true
  notification_channels = var.notification_channels

  # Database performance tuning
  database_flags = var.database_flags

  # Labels for cost tracking and compliance
  labels = merge(var.common_labels, {
    environment     = var.environment
    database-size   = "large"
    cost-type      = "production"
    sla-tier       = "critical"
    compliance     = "required"
    backup-required = "true"
  })

  # IAM users for production access
  iam_users = var.database_iam_users

  # Depends on VPC networking being ready
  depends_on = [module.vpc]
}

# =============================================================================
# KUBERNETES PROVIDER CONFIGURATION
# =============================================================================

# Configure Kubernetes provider after GKE cluster is ready
provider "kubernetes" {
  host                   = module.gke.kubernetes_host
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = module.gke.kubernetes_cluster_ca_certificate
}

# =============================================================================
# PRODUCTION NAMESPACES
# =============================================================================

# Production application namespace
resource "kubernetes_namespace" "production" {
  metadata {
    name = "production"
    
    labels = {
      environment = var.environment
      purpose     = "production-applications"
      managed-by  = "terraform"
      tier        = "critical"
    }
    
    annotations = {
      "scheduler.alpha.kubernetes.io/node-selector" = "environment=production"
    }
  }

  depends_on = [module.gke]
}

# Monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    
    labels = {
      environment = var.environment
      purpose     = "monitoring-stack"
      managed-by  = "terraform"
    }
  }

  depends_on = [module.gke]
}

# Security namespace for security tools
resource "kubernetes_namespace" "security" {
  metadata {
    name = "security"
    
    labels = {
      environment = var.environment
      purpose     = "security-tools"
      managed-by  = "terraform"
    }
  }

  depends_on = [module.gke]
}

# =============================================================================
# KUBERNETES SECRETS (Production credential management)
# =============================================================================

# Create Kubernetes secret with CloudSQL credentials
resource "kubernetes_secret" "cloudsql_credentials" {
  metadata {
    name      = "cloudsql-credentials"
    namespace = "production"
    
    labels = {
      app         = "cloudsql"
      environment = var.environment
      managed-by  = "terraform"
      tier        = "critical"
    }
    
    annotations = {
      "kubernetes.io/service-account.name" = "backend-sa"
    }
  }

  # Use CloudSQL module outputs for automatic credential management
  data = module.cloudsql.kubernetes_secret_data

  type = "Opaque"

  depends_on = [module.gke, module.cloudsql, kubernetes_namespace.production]
}

# Create service account key secret for Cloud SQL Proxy
resource "google_service_account" "cloudsql_proxy_prod" {
  account_id   = "${var.environment}-cloudsql-proxy"
  display_name = "CloudSQL Proxy for ${var.environment}"
  description  = "Production service account for CloudSQL Proxy"
}

# Grant CloudSQL client role to service account
resource "google_project_iam_member" "cloudsql_client_prod" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudsql_proxy_prod.email}"
}

# Create service account key
resource "google_service_account_key" "cloudsql_proxy_key_prod" {
  service_account_id = google_service_account.cloudsql_proxy_prod.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# Store service account key in Kubernetes secret
resource "kubernetes_secret" "cloudsql_proxy_key" {
  metadata {
    name      = "cloudsql-proxy-key"
    namespace = "production"
    
    labels = {
      app         = "cloudsql-proxy"
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  data = {
    "service-account.json" = base64decode(google_service_account_key.cloudsql_proxy_key_prod.private_key)
  }

  type = "Opaque"

  depends_on = [module.gke, kubernetes_namespace.production]
}

# =============================================================================
# PRODUCTION MONITORING (Basic setup - can be extended)
# =============================================================================

# Create ConfigMap for monitoring configuration
resource "kubernetes_config_map" "monitoring_config" {
  metadata {
    name      = "monitoring-config"
    namespace = "monitoring"
    
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  data = {
    prometheus_config = file("${path.module}/configs/prometheus.yml")
    alerting_rules   = file("${path.module}/configs/alerting-rules.yml")
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# =============================================================================
# PRODUCTION RESOURCE QUOTAS AND LIMITS
# =============================================================================

# Resource quota for production namespace
resource "kubernetes_resource_quota" "production_quota" {
  metadata {
    name      = "production-quota"
    namespace = "production"
  }
  
  spec {
    hard = {
      "requests.cpu"    = "10"     # 10 CPU cores
      "requests.memory" = "20Gi"   # 20GB memory
      "limits.cpu"      = "20"     # 20 CPU cores limit
      "limits.memory"   = "40Gi"   # 40GB memory limit
      "persistentvolumeclaims" = "10"
      "services"        = "20"
      "secrets"         = "50"
      "configmaps"      = "50"
    }
  }

  depends_on = [kubernetes_namespace.production]
}

# Limit range for production pods
resource "kubernetes_limit_range" "production_limits" {
  metadata {
    name      = "production-limits"
    namespace = "production"
  }
  
  spec {
    limit {
      type = "Pod"
      max = {
        cpu    = "2"
        memory = "4Gi"
      }
      min = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    
    limit {
      type = "Container"
      default = {
        cpu    = "500m"
        memory = "512Mi"
      }
      default_request = {
        cpu    = "200m"
        memory = "256Mi"
      }
    }
  }

  depends_on = [kubernetes_namespace.production]
}

# =============================================================================
# PRODUCTION NETWORK POLICIES
# =============================================================================

# Network policy for production namespace isolation
resource "kubernetes_network_policy" "production_isolation" {
  metadata {
    name      = "production-isolation"
    namespace = "production"
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress", "Egress"]

    # Allow ingress from monitoring namespace
    ingress {
      from {
        namespace_selector {
          match_labels = {
            purpose = "monitoring-stack"
          }
        }
      }
    }

    # Allow egress to CloudSQL and external APIs
    egress {
      # CloudSQL access
      to {
        ip_block {
          cidr = "${module.cloudsql.private_ip_address}/32"
        }
      }
      ports {
        protocol = "TCP"
        port     = "5432"
      }
    }

    # Allow DNS resolution
    egress {
      to {}
      ports {
        protocol = "UDP"
        port     = "53"
      }
    }

    # Allow HTTPS egress
    egress {
      to {}
      ports {
        protocol = "TCP"
        port     = "443"
      }
    }
  }

  depends_on = [kubernetes_namespace.production]
}