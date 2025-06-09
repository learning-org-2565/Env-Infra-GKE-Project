# =============================================================================
# modules/vpc/outputs.tf
# =============================================================================
output "vpc_id" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "The self link of the VPC"
  value       = google_compute_network.vpc.self_link
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = google_compute_subnetwork.public.id
}

output "public_subnet_name" {
  description = "The name of the public subnet"
  value       = google_compute_subnetwork.public.name
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = google_compute_subnetwork.private.id
}

output "private_subnet_name" {
  description = "The name of the private subnet"
  value       = google_compute_subnetwork.private.name
}

output "pod_cidr" {
  description = "The CIDR range for GKE pods"
  value       = google_compute_subnetwork.public.secondary_ip_range[0].ip_cidr_range
}

output "service_cidr" {
  description = "The CIDR range for GKE services"
  value       = google_compute_subnetwork.public.secondary_ip_range[1].ip_cidr_range
}

output "nat_gateway_name" {
  description = "The name of the NAT gateway"
  value       = var.enable_nat_gateway ? google_compute_router_nat.nat[0].name : null
}

output "router_name" {
  description = "The name of the Cloud Router"
  value       = var.enable_nat_gateway ? google_compute_router.router[0].name : null
}
