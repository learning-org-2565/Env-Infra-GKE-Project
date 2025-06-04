# =============================================================================
# VPC MODULE VERSIONS - modules/vpc/versions.tf
# Provider and Terraform version requirements
# =============================================================================

terraform {
  # Minimum Terraform version required
  required_version = ">= 1.0"

  # Required providers with version constraints
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"  # Use latest 5.x version
    }
    
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"  # For beta features if needed
    }
  }

  # Optional: Add provider requirements for features
  # Use this block if you want to enforce specific provider features
  experiments = []
}