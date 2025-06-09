variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
}

variable "gke_cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "vpc_network" {
  description = "VPC network self link"
  type        = string
}

variable "vpc_subnetwork" {
  description = "VPC subnetwork self link"
  type        = string
}

variable "pod_range_name" {
  description = "Name of the secondary range for pods"
  type        = string
  default     = "pod-range"
}

variable "service_range_name" {
  description = "Name of the secondary range for services"
  type        = string
  default     = "service-range"
}

variable "service_account_email" {
  description = "Service account email to use for GKE cluster and nodes"
  type        = string
  default     = "githubactions-sa@turnkey-guild-441104-f3.iam.gserviceaccount.com"
}

variable "node_zones" {
  description = "List of zones for node placement (minimum 2 zones required)"
  type        = list(string)
  default     = []
  
  validation {
    condition     = length(var.node_zones) == 0 || length(var.node_zones) >= 2
    error_message = "If node_zones is specified, it must contain at least 2 zones to avoid storage quota issues."
  }
}

variable "gke_num_nodes" {
  description = "Number of GKE nodes per zone"
  type        = number
  default     = 1

  validation {
    condition     = var.gke_num_nodes >= 1 && var.gke_num_nodes <= 10
    error_message = "Number of nodes must be between 1 and 10."
  }
}

variable "gke_min_nodes" {
  description = "Minimum number of GKE nodes per zone for autoscaling"
  type        = number
  default     = 1

  validation {
    condition     = var.gke_min_nodes >= 1
    error_message = "Minimum nodes must be at least 1."
  }
}

variable "gke_max_nodes" {
  description = "Maximum number of GKE nodes per zone for autoscaling"
  type        = number
  default     = 3

  validation {
    condition     = var.gke_max_nodes >= 1 && var.gke_max_nodes <= 100
    error_message = "Maximum nodes must be between 1 and 100."
  }
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "gke_disk_type" {
  description = "Disk type for GKE nodes"
  type        = string
  default     = "pd-standard"

  validation {
    condition     = contains(["pd-standard", "pd-balanced", "pd-ssd"], var.gke_disk_type)
    error_message = "Disk type must be one of: pd-standard, pd-balanced, pd-ssd."
  }
}

variable "gke_disk_size_gb" {
  description = "Disk size for GKE nodes in GB"
  type        = number
  default     = 100

  validation {
    condition     = var.gke_disk_size_gb >= 20 && var.gke_disk_size_gb <= 2000
    error_message = "Disk size must be between 20GB and 2000GB."
  }
}

variable "environment" {
  description = "Environment label for resources"
  type        = string
  default     = "dev"
}

variable "enable_network_policy" {
  description = "Enable network policy (Calico)"
  type        = bool
  default     = true
}

variable "enable_shielded_nodes" {
  description = "Enable shielded nodes for better security"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}