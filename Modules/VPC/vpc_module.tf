# =============================================================================
# modules/vpc/main.tf
# =============================================================================
locals {
  common_labels = merge(var.labels, {
    managed_by = "terraform"
    module     = "vpc"
  })
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description             = "VPC managed by Terraform"
  routing_mode            = "REGIONAL"
}

# Public Subnet (for GKE)
resource "google_compute_subnetwork" "public" {
  name          = "${var.vpc_name}-public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  description   = "Public subnet for GKE and external-facing resources"

  # Secondary IP ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "pod-range"
    ip_cidr_range = var.pod_cidr
  }

  secondary_ip_range {
    range_name    = "service-range"
    ip_cidr_range = var.service_cidr
  }

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_10_MIN"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

# Private Subnet
resource "google_compute_subnetwork" "private" {
  name                     = "${var.vpc_name}-private-subnet"
  ip_cidr_range            = var.private_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
  description              = "Private subnet for internal resources"

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_10_MIN"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

# Cloud Router for NAT Gateway
resource "google_compute_router" "router" {
  count   = var.enable_nat_gateway ? 1 : 0
  name    = "${var.vpc_name}-nat-router"
  network = google_compute_network.vpc.id
  region  = var.region
}

# NAT Gateway
resource "google_compute_router_nat" "nat" {
  count                              = var.enable_nat_gateway ? 1 : 0
  name                               = "${var.vpc_name}-nat-gateway"
  router                             = google_compute_router.router[0].name
  region                             = google_compute_router.router[0].region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall Rules
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

  source_ranges = ["10.0.0.0/8"]
  description   = "Allow all internal traffic within the VPC"
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.vpc_name}-allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["ssh"]
  source_ranges = ["0.0.0.0/0"]
  description   = "Allow SSH access to instances with the ssh tag"
}

resource "google_compute_firewall" "web" {
  name    = "${var.vpc_name}-allow-web"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  target_tags   = ["web"]
  source_ranges = ["0.0.0.0/0"]
  description   = "Allow HTTP and HTTPS traffic to web instances"
}

resource "google_compute_firewall" "gke" {
  name    = "${var.vpc_name}-allow-gke-master"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
  }

  target_tags   = ["gke-node"]
  source_ranges = ["172.16.0.0/28"]
  description   = "Allow communication from GKE master to nodes"
}

resource "google_compute_firewall" "health_checks" {
  name    = "${var.vpc_name}-allow-health-checks"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  description   = "Allow health checks from GCP load balancers"
}