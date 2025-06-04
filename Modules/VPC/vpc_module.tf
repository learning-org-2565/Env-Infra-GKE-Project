# =============================================================================
# VPC MODULE - modules/vpc/main.tf
# Shared networking foundation for all environments
# =============================================================================

# Main VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description             = "VPC for ${var.environment} environment"
  routing_mode            = "REGIONAL"
  
  # Add lifecycle management
  lifecycle {
    prevent_destroy = true
  }
}

# Public Subnet (for GKE and other resources that need internet access)
resource "google_compute_subnetwork" "public" {
  name          = "${var.vpc_name}-public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  description   = "Public subnet for GKE and internet-facing resources"

  # Enable private Google access for better security
  private_ip_google_access = true

  # Secondary IP ranges for GKE
  secondary_ip_range {
    range_name    = "pod-range"
    ip_cidr_range = var.pod_cidr
  }

  secondary_ip_range {
    range_name    = "service-range" 
    ip_cidr_range = var.service_cidr
  }

  # Log subnet flow for monitoring
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Private Subnet (for databases and internal services)
resource "google_compute_subnetwork" "private" {
  name          = "${var.vpc_name}-private-subnet"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  description   = "Private subnet for databases and internal resources"

  # Enable private Google access for API calls without public IP
  private_ip_google_access = true

  # Log subnet flow for monitoring
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Cloud Router for NAT Gateway
resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-nat-router"
  network = google_compute_network.vpc.id
  region  = var.region
  
  description = "Router for NAT gateway to provide internet access to private resources"
}

# NAT Gateway (allows private resources to access internet)
resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat-gateway"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  # Configure which subnets can use this NAT
  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  # Enable logging for troubleshooting
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  # Auto-allocate IPs based on usage
  min_ports_per_vm                 = 64
  udp_idle_timeout_sec            = 30
  icmp_idle_timeout_sec           = 30
  tcp_established_idle_timeout_sec = 1200
  tcp_transitory_idle_timeout_sec  = 30
}

# =============================================================================
# FIREWALL RULES
# =============================================================================

# Allow all internal communication within VPC
resource "google_compute_firewall" "internal" {
  name    = "${var.vpc_name}-allow-internal"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.public_subnet_cidr,
    var.private_subnet_cidr,
    var.pod_cidr,
    var.service_cidr
  ]
  
  description = "Allow all internal traffic within the VPC and secondary ranges"
}

# Allow SSH access to instances with ssh tag
resource "google_compute_firewall" "ssh" {
  name    = "${var.vpc_name}-allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["ssh"]
  source_ranges = var.ssh_source_ranges
  description   = "Allow SSH access to instances with ssh tag"
}

# Allow HTTP/HTTPS traffic to web instances
resource "google_compute_firewall" "web" {
  name    = "${var.vpc_name}-allow-web"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "3000"] # Added common dev ports
  }

  target_tags   = ["web"]
  source_ranges = ["0.0.0.0/0"]
  description   = "Allow HTTP/HTTPS traffic to web instances"
}

# Allow GKE master to communicate with nodes
resource "google_compute_firewall" "gke_master" {
  name    = "${var.vpc_name}-allow-gke-master"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["443", "10250"] # Kubernetes API and kubelet
  }

  target_tags   = ["gke-node"]
  source_ranges = [var.gke_master_cidr]
  description   = "Allow communication from GKE master to nodes"
}

# Allow health checks from Google Cloud Load Balancers
resource "google_compute_firewall" "health_checks" {
  name    = "${var.vpc_name}-allow-health-checks"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16",   # Google health check IPs
    "130.211.0.0/22"   # Google health check IPs
  ]
  
  description = "Allow health checks from Google Cloud Load Balancers"
}

# Allow NodePort services (for GKE services)
resource "google_compute_firewall" "gke_nodeports" {
  name    = "${var.vpc_name}-allow-gke-nodeports"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"] # NodePort range
  }

  target_tags   = ["gke-node"]
  source_ranges = ["0.0.0.0/0"] # Can be restricted based on requirements
  description   = "Allow NodePort services for GKE"
}