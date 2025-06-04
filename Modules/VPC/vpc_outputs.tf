# =============================================================================
# VPC MODULE OUTPUTS - modules/vpc/outputs.tf
# Output values that other modules will use
# =============================================================================

# VPC Network Outputs
output "vpc_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "The self-link of the VPC network (used by other resources)"
  value       = google_compute_network.vpc.self_link
}

# Subnet Outputs
output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = google_compute_subnetwork.public.id
}

output "public_subnet_name" {
  description = "The name of the public subnet"
  value       = google_compute_subnetwork.public.name
}

output "public_subnet_self_link" {
  description = "The self-link of the public subnet (for GKE)"
  value       = google_compute_subnetwork.public.self_link
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = google_compute_subnetwork.private.id
}

output "private_subnet_name" {
  description = "The name of the private subnet"
  value       = google_compute_subnetwork.private.name
}

output "private_subnet_self_link" {
  description = "The self-link of the private subnet (for CloudSQL)"
  value       = google_compute_subnetwork.private.self_link
}

# Secondary IP Range Outputs (for GKE)
output "pod_cidr" {
  description = "The CIDR range for GKE pods"
  value       = google_compute_subnetwork.public.secondary_ip_range[0].ip_cidr_range
}

output "pod_range_name" {
  description = "The name of the pod IP range (for GKE configuration)"
  value       = google_compute_subnetwork.public.secondary_ip_range[0].range_name
}

output "service_cidr" {
  description = "The CIDR range for GKE services"
  value       = google_compute_subnetwork.public.secondary_ip_range[1].ip_cidr_range
}

output "service_range_name" {
  description = "The name of the service IP range (for GKE configuration)"
  value       = google_compute_subnetwork.public.secondary_ip_range[1].range_name
}

# NAT Gateway Outputs
output "nat_gateway_name" {
  description = "The name of the NAT gateway"
  value       = google_compute_router_nat.nat.name
}

output "nat_router_name" {
  description = "The name of the Cloud Router used by NAT"
  value       = google_compute_router.router.name
}

# Regional Information
output "region" {
  description = "The region where the VPC is created"
  value       = var.region
}

output "project_id" {
  description = "The project ID where the VPC is created"
  value       = var.project_id
}

# Firewall Information
output "firewall_rules" {
  description = "List of firewall rules created"
  value = {
    internal      = google_compute_firewall.internal.name
    ssh           = google_compute_firewall.ssh.name
    web           = google_compute_firewall.web.name
    gke_master    = google_compute_firewall.gke_master.name
    health_checks = google_compute_firewall.health_checks.name
    gke_nodeports = google_compute_firewall.gke_nodeports.name
  }
}

# Network Configuration Summary
output "network_config" {
  description = "Summary of network configuration for documentation"
  value = {
    vpc_name              = google_compute_network.vpc.name
    public_subnet_cidr    = google_compute_subnetwork.public.ip_cidr_range
    private_subnet_cidr   = google_compute_subnetwork.private.ip_cidr_range
    pod_cidr             = google_compute_subnetwork.public.secondary_ip_range[0].ip_cidr_range
    service_cidr         = google_compute_subnetwork.public.secondary_ip_range[1].ip_cidr_range
    region               = var.region
    environment          = var.environment
  }
}

# Connection Information for Other Modules
output "gke_network_config" {
  description = "Network configuration specifically for GKE module"
  value = {
    network               = google_compute_network.vpc.self_link
    subnetwork           = google_compute_subnetwork.public.self_link
    pod_range_name       = google_compute_subnetwork.public.secondary_ip_range[0].range_name
    service_range_name   = google_compute_subnetwork.public.secondary_ip_range[1].range_name
    master_cidr          = var.gke_master_cidr
  }
}

output "cloudsql_network_config" {
  description = "Network configuration specifically for CloudSQL module"
  value = {
    network          = google_compute_network.vpc.id
    private_subnet   = google_compute_subnetwork.private.self_link
    vpc_self_link    = google_compute_network.vpc.self_link
  }
}