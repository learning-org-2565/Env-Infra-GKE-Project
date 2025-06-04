# =============================================================================
# VPC MODULE VARIABLES - modules/vpc/variables.tf
# Input variables for the VPC module
# =============================================================================

# Required Variables (must be provided by calling environment)
variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
  
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID cannot be empty."
  }
}

variable "region" {
  description = "The GCP region where regional resources will be created"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Region must be a valid GCP region format (e.g., us-central1)."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# VPC Configuration
variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "devops-vpc"
  
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.vpc_name))
    error_message = "VPC name must be lowercase letters, numbers, and hyphens only."
  }
}

# Subnet CIDR Ranges
variable "public_subnet_cidr" {
  description = "CIDR range for the public subnet (for GKE and internet-facing resources)"
  type        = string
  default     = "10.0.1.0/24"
  
  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Public subnet CIDR must be a valid CIDR block."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR range for the private subnet (for databases and internal resources)"
  type        = string
  default     = "10.0.2.0/24"
  
  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "Private subnet CIDR must be a valid CIDR block."
  }
}

# GKE Secondary IP Ranges
variable "pod_cidr" {
  description = "CIDR range for GKE pods (secondary IP range)"
  type        = string
  default     = "10.1.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.pod_cidr, 0))
    error_message = "Pod CIDR must be a valid CIDR block."
  }
}

variable "service_cidr" {
  description = "CIDR range for GKE services (secondary IP range)"
  type        = string
  default     = "10.2.0.0/20"
  
  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "Service CIDR must be a valid CIDR block."
  }
}

# GKE Master Configuration
variable "gke_master_cidr" {
  description = "CIDR range for GKE master nodes (for firewall rules)"
  type        = string
  default     = "172.16.0.0/28"
  
  validation {
    condition     = can(cidrhost(var.gke_master_cidr, 0))
    error_message = "GKE master CIDR must be a valid CIDR block."
  }
}

# Security Configuration
variable "ssh_source_ranges" {
  description = "List of CIDR ranges allowed to SSH to instances"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production!
  
  validation {
    condition = alltrue([
      for cidr in var.ssh_source_ranges : can(cidrhost(cidr, 0))
    ])
    error_message = "All SSH source ranges must be valid CIDR blocks."
  }
}

# Resource Labels and Tags
variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default = {
    managed-by = "terraform"
    purpose    = "devops-infrastructure"
  }
}

variable "network_tags" {
  description = "Additional network tags to apply to resources"
  type        = list(string)
  default     = []
}

# Advanced Networking Options
variable "enable_flow_logs" {
  description = "Enable VPC flow logs for network monitoring"
  type        = bool
  default     = true
}

variable "flow_log_sampling" {
  description = "Sampling rate for flow logs (0.0 to 1.0)"
  type        = number
  default     = 0.5
  
  validation {
    condition     = var.flow_log_sampling >= 0.0 && var.flow_log_sampling <= 1.0
    error_message = "Flow log sampling must be between 0.0 and 1.0."
  }
}

variable "enable_private_google_access" {
  description = "Enable private Google access for subnets"
  type        = bool
  default     = true
}

# NAT Configuration
variable "nat_min_ports_per_vm" {
  description = "Minimum number of ports allocated to a VM from this NAT"
  type        = number
  default     = 64
  
  validation {
    condition     = var.nat_min_ports_per_vm >= 64
    error_message = "NAT min ports per VM must be at least 64."
  }
}

variable "nat_log_filter" {
  description = "Logging filter for NAT gateway (ERRORS_ONLY, TRANSLATIONS_ONLY, ALL)"
  type        = string
  default     = "ERRORS_ONLY"
  
  validation {
    condition     = contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], var.nat_log_filter)
    error_message = "NAT log filter must be one of: ERRORS_ONLY, TRANSLATIONS_ONLY, ALL."
  }
}