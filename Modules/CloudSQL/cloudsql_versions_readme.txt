# =============================================================================
# CLOUDSQL MODULE VERSIONS - modules/cloudsql/versions.tf
# Provider and Terraform version requirements
# =============================================================================

terraform {
  # Minimum Terraform version required
  required_version = ">= 1.0"

  # Required providers with version constraints
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }

    # For generating random passwords
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }

    # For time-based resources (password rotation)
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }

    # For PostgreSQL role management (optional)
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.20"
    }

    # For Kubernetes resources (optional)
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}