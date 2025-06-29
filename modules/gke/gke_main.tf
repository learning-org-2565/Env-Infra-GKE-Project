locals {
  default_zones = [
    "${var.region}-a",
    "${var.region}-b",
    "${var.region}-c"
  ]
  
  node_zones = length(var.node_zones) > 0 ? var.node_zones : local.default_zones
  
  common_labels = merge(var.labels, {
    managed_by  = "terraform"
    module      = "gke"
    environment = var.environment
  })
}

resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name
  location = var.region

  node_locations = local.node_zones

  initial_node_count = var.gke_num_nodes

  node_config {
    service_account = var.service_account_email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    tags = ["gke-node", "web"]
    
    labels = local.common_labels
  }


  network    = var.vpc_network
  subnetwork = var.vpc_subnetwork

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_range_name
    services_secondary_range_name = var.service_range_name
  }

  networking_mode = "VPC_NATIVE"

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  }

  dynamic "network_policy" {
    for_each = var.enable_network_policy ? [1] : []
    content {
      enabled  = true
      provider = "CALICO"
    }
  }

  resource_labels = local.common_labels

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.gke_cluster_name}-node-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name

  node_count = var.gke_num_nodes

  autoscaling {
    min_node_count = var.gke_min_nodes
    max_node_count = var.gke_max_nodes
  }

  node_config {
    machine_type = var.gke_machine_type

    disk_size_gb = var.gke_disk_size_gb
    disk_type    = var.gke_disk_type

    service_account = var.service_account_email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    tags = ["gke-node", "web"]

    labels = merge(local.common_labels, {
      node_pool = "primary"
    })

    dynamic "shielded_instance_config" {
      for_each = var.enable_shielded_nodes ? [1] : []
      content {
        enable_secure_boot = true
      }
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [google_container_cluster.primary]
}
