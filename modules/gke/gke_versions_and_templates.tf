# Project Structure:
# .
# ├── modules/
# │   ├── vpc/            (existing)
# │   └── gke/            (new)
# │       ├── main.tf
# │       ├── variables.tf
# │       ├── outputs.tf
# │       └── versions.tf
# ├── main.tf             (updated to use both modules)
# ├── variables.tf
# ├── outputs.tf
# ├── providers.tf
# └── backend.tf

# =============================================================================
# modules/gke/versions.tf
# =============================================================================
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0, < 6.0"
    }
  }
}