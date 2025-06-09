# # =============================================================================
# # GKE SERVICE ACCOUNT - modules/gke/service-account.tf
# # Service account and IAM configuration for GKE nodes
# # =============================================================================

# # Create dedicated service account for GKE nodes
# resource "google_service_account" "gke_sa" {
#   account_id   = "${var.cluster_name}-gke-sa"
#   display_name = "GKE Service Account for ${var.cluster_name}"
#   description  = "Service account used by GKE nodes in ${var.environment} environment"
#   project      = var.project_id
# }

# # =============================================================================
# # REQUIRED GKE NODE ROLES
# # =============================================================================

# # Essential roles for GKE node functionality
# resource "google_project_iam_member" "gke_sa_essential_roles" {
#   for_each = toset([
#     # Core GKE roles (always required)
#     "roles/logging.logWriter",           # Write logs to Cloud Logging
#     "roles/monitoring.metricWriter",     # Write metrics to Cloud Monitoring
#     "roles/monitoring.viewer",           # Read monitoring data
#     "roles/storage.objectViewer",        # Pull container images
#   ])

#   project = var.project_id
#   role    = each.key
#   member  = "serviceAccount:${google_service_account.gke_sa.email}"
# }

# # =============================================================================
# # ENVIRONMENT-SPECIFIC ROLES
# # =============================================================================

# # Additional roles for development environment
# resource "google_project_iam_member" "gke_sa_dev_roles" {
#   for_each = var.environment == "dev" ? toset([
#     "roles/artifactregistry.reader",    # Read from Artifact Registry
#     "roles/container.developer",        # Deploy and manage workloads
#   ]) : toset([])

#   project = var.project_id
#   role    = each.key
#   member  = "serviceAccount:${google_service_account.gke_sa.email}"
# }

# # Additional roles for production environment
# resource "google_project_iam_member" "gke_sa_prod_roles" {
#   for_each = var.environment == "prod" ? toset([
#     "roles/artifactregistry.reader",    # Read from Artifact Registry
#     "roles/container.nodeServiceAgent", # GKE node service agent
#     "roles/cloudsql.client",           # Connect to Cloud SQL (if needed)
#   ]) : toset([])

#   project = var.project_id
#   role    = each.key
#   member  = "serviceAccount:${google_service_account.gke_sa.email}"
# }

# # =============================================================================
# # OPTIONAL ADDITIONAL ROLES
# # =============================================================================

# # Additional custom roles based on requirements
# resource "google_project_iam_member" "gke_sa_additional_roles" {
#   for_each = toset(var.additional_service_account_roles)

#   project = var.project_id
#   role    = each.key
#   member  = "serviceAccount:${google_service_account.gke_sa.email}"
# }

# # =============================================================================
# # WORKLOAD IDENTITY SETUP (for pod-to-GCP service authentication)
# # =============================================================================

# # Workload Identity binding for Kubernetes service accounts
# resource "google_service_account_iam_binding" "workload_identity_binding" {
#   count = length(var.workload_identity_service_accounts)

#   service_account_id = google_service_account.gke_sa.name
#   role               = "roles/iam.workloadIdentityUser"

#   members = [
#     for ksa in var.workload_identity_service_accounts :
#     "serviceAccount:${var.project_id}.svc.id.goog[${ksa.namespace}/${ksa.name}]"
#   ]
# }

# # =============================================================================
# # SERVICE ACCOUNT KEY (for external access if needed)
# # =============================================================================

# # Create service account key only if explicitly requested
# resource "google_service_account_key" "gke_sa_key" {
#   count = var.create_service_account_key ? 1 : 0

#   service_account_id = google_service_account.gke_sa.name
#   public_key_type    = "TYPE_X509_PEM_FILE"

#   # Store key securely
#   keepers = {
#     cluster_name = var.cluster_name
#     environment  = var.environment
#   }
# }

# # =============================================================================
# # IAM CONDITIONS (for enhanced security in prod)
# # =============================================================================

# # Conditional IAM binding for production environment
# resource "google_project_iam_member" "gke_sa_conditional_roles" {
#   for_each = var.environment == "prod" ? toset(var.conditional_roles) : toset([])

#   project = var.project_id
#   role    = each.value.role
#   member  = "serviceAccount:${google_service_account.gke_sa.email}"

#   # Add IAM condition for time-based or resource-based access
#   dynamic "condition" {
#     for_each = each.value.condition != null ? [each.value.condition] : []
#     content {
#       title       = condition.value.title
#       description = condition.value.description
#       expression  = condition.value.expression
#     }
#   }
# }