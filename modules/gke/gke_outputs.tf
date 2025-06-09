output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_host" {
  description = "GKE Cluster Host URL"
  value       = "https://${google_container_cluster.primary.endpoint}"
  sensitive   = true
}

output "cluster_location" {
  description = "The location (region) of the GKE cluster"
  value       = google_container_cluster.primary.location
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "node_pool_name" {
  description = "The name of the primary node pool"
  value       = google_container_node_pool.primary_nodes.name
}

output "service_account_email" {
  description = "The service account email used for GKE nodes"
  value       = var.service_account_email
}

output "kubectl_command" {
  description = "Command to get kubectl credentials"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id}"
}

output "cluster_zones" {
  description = "The zones where the cluster nodes are located"
  value       = google_container_cluster.primary.node_locations
}