# GKE Module

## ⚓ Overview

This module creates a production-ready Google Kubernetes Engine (GKE) cluster with environment-specific configurations. It supports different settings for development and production environments while maintaining security best practices.

## 🏗️ Architecture

```
GKE Cluster
├── Control Plane (Managed by Google)
│   ├── Kubernetes API Server
│   ├── etcd
│   └── Scheduler
├── Primary Node Pool
│   ├── Dev: 1 node (e2-micro)
│   └── Prod: 3+ nodes (e2-standard-4)
└── High-Memory Pool (Prod Only)
    └── Data-intensive workloads
```

## 📋 Features

### Core Features
- ✅ **VPC-native networking** with IP alias ranges
- ✅ **Workload Identity** for secure pod-to-GCP authentication  
- ✅ **Network policies** with Calico CNI
- ✅ **Shielded GKE nodes** for enhanced security
- ✅ **Autoscaling** with configurable min/max nodes
- ✅ **Auto-repair and auto-upgrade** for node management

### Environment-Specific Features
- ✅ **Dev**: Single zone, small instances, spot instances
- ✅ **Prod**: Multi-zone, larger instances, maintenance windows
- ✅ **Prod**: Database encryption, binary authorization
- ✅ **Prod**: High-memory node pool for data workloads

## 🔧 Usage

### Basic Usage
```hcl
module "gke" {
  source = "./modules/gke"

  # Required variables
  project_id        = "my-gcp-project"
  region           = "us-central1"
  environment      = "dev"
  cluster_name     = "my-cluster"

  # Network configuration (from VPC module)
  network           = module.vpc.gke_network_config.network
  subnetwork        = module.vpc.gke_network_config.subnetwork
  pod_range_name    = module.vpc.gke_network_config.pod_range_name
  service_range_name = module.vpc.gke_network_config.service_range_name
}
```

### Development Environment
```hcl
module "gke_dev" {
  source = "./modules/gke"

  project_id   = "my-project"
  region      = "us-central1"
  environment = "dev"
  cluster_name = "dev-cluster"

  # Dev-specific settings
  machine_type           = "e2-micro"
  dev_node_count        = 1
  enable_autoscaling    = false
  enable_spot_instances = true
  disk_size_gb         = 50
  disk_type            = "pd-standard"

  # Network from VPC module
  network           = module.vpc.gke_network_config.network
  subnetwork        = module.vpc.gke_network_config.subnetwork
  pod_range_name    = module.vpc.gke_network_config.pod_range_name
  service_range_name = module.vpc.gke_network_config.service_range_name
}
```

### Production Environment
```hcl
module "gke_prod" {
  source = "./modules/gke"

  project_id   = "my-project"
  region      = "us-central1"
  environment = "prod"
  cluster_name = "prod-cluster"

  # Prod-specific settings
  machine_type       = "e2-standard-4"
  enable_autoscaling = true
  min_node_count    = 3
  max_node_count    = 10
  disk_size_gb      = 100
  disk_type         = "pd-ssd"

  # High-memory pool for data workloads
  enable_high_memory_pool   = true
  high_memory_machine_type  = "n2-highmem-4"
  high_memory_max_nodes     = 5

  # Security features
  database_encryption_key = "projects/my-project/locations/us-central1/keyRings/my-ring/cryptoKeys/my-key"
  
  # Maintenance window
  maintenance_start_time = "2023-01-01T04:00:00Z"
  maintenance_end_time   = "2023-01-01T06:00:00Z"

  # Network from VPC module
  network           = module.vpc.gke_network_config.network
  subnetwork        = module.vpc.gke_network_config.subnetwork
  pod_range_name    = module.vpc.gke_network_config.pod_range_name
  service_range_name = module.vpc.gke_network_config.service_range_name
}
```

## 📥 Inputs

### Required Inputs
| Name | Description | Type | Required |
|------|-------------|------|----------|
| project_id | GCP project ID | string | yes |
| region | GCP region | string | yes |
| environment | Environment (dev/staging/prod) | string | yes |
| cluster_name | GKE cluster name | string | yes |
| network | VPC network self-link | string | yes |
| subnetwork | VPC subnetwork self-link | string | yes |

### Environment-Specific Defaults
| Setting | Dev Default | Prod Default |
|---------|-------------|--------------|
| machine_type | e2-micro | e2-standard-4 |
| node_count | 1 (fixed) | 3-10 (autoscaling) |
| disk_size_gb | 50 | 100 |
| zones | Single zone | Multi-zone |
| spot_instances | true | false |

## 📤 Outputs

### Cluster Information
| Name | Description |
|------|-------------|
| cluster_name | Name of the GKE cluster |
| cluster_endpoint | Kubernetes API server endpoint |
| cluster_ca_certificate | CA certificate for cluster |
| kubectl_config_command | Command to configure kubectl |

### Authentication
| Name | Description |
|------|-------------|
| kubernetes_host | Kubernetes API host for provider |
| kubernetes_token | Auth token for Kubernetes provider |
| service_account_email | GKE node service account email |

## 🔒 Security Features

### Node Security
- **Shielded GKE nodes** with secure boot and integrity monitoring
- **Container-Optimized OS** with automatic security updates
- **Workload Identity** for pod-to-GCP service authentication
- **Network policies** for micro-segmentation

### Cluster Security
- **Private nodes** with no external IP addresses
- **Authorized networks** to control API server access
- **Binary authorization** for container image security (prod)
- **Database encryption** with customer-managed keys (prod)

### IAM and Service Accounts
- **Minimal IAM roles** following least-privilege principle
- **Dedicated service account** for GKE nodes
- **Workload Identity** mapping for Kubernetes service accounts

## 📊 Environment Differences

### Development Environment
- **Cost-optimized**: Small instances, spot VMs, single zone
- **Simple setup**: Fixed node count, minimal features
- **Fast iteration**: Auto-upgrade enabled, relaxed security

### Production Environment  
- **High availability**: Multi-zone, larger instances
- **Enhanced security**: Encryption, binary authorization
- **Scheduled maintenance**: Controlled upgrade windows
- **Specialized workloads**: High-memory node pool

## 🚀 Post-Deployment Setup

### Configure kubectl
```bash
# Get cluster credentials
gcloud container clusters get-credentials CLUSTER_NAME \
  --region REGION --project PROJECT_ID

# Verify connection
kubectl get nodes
```

### Install Essential Add-ons
```bash
# Install ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

## 💰 Cost Optimization

### Development
- Use **spot instances** for 60-80% cost savings
- **Single zone** deployment to avoid cross-zone charges
- **Smaller disk sizes** and standard disks
- **Auto-scaling to zero** during off-hours

### Production
- **Committed use discounts** for predictable workloads
- **Balanced persistent disks** for cost-performance balance
- **Resource quotas** to prevent runaway costs
- **Pod disruption budgets** for efficient scaling

## 🔧 Troubleshooting

### Common Issues

#### Node Pool Not Scaling
```bash
# Check cluster autoscaler status
kubectl get events --sort-by=.metadata.creationTimestamp

# Check node pool status
gcloud container node-pools describe POOL_NAME \
  --cluster=CLUSTER_NAME --region=REGION
```

#### Pod Scheduling Issues
```bash
# Check node resources
kubectl describe nodes

# Check pod resource requests
kubectl describe pod POD_NAME
```

#### Network Connectivity
```bash
# Test pod-to-pod communication
kubectl run test-pod --image=busybox --rm -it -- sh

# Check network policies
kubectl get networkpolicies
```

## 🏷️ Version History

- **v1.0.0**: Initial release with basic GKE cluster
- **v1.1.0**: Added Workload Identity and network policies
- **v1.2.0**: Environment-specific configurations
- **v1.3.0**: High-memory node pool and production features