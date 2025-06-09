# VPC Module

## 🌐 Overview

This module creates a production-ready VPC network with public and private subnets, NAT gateway, and comprehensive firewall rules. It's designed to be shared across multiple environments (dev, staging, prod).

## 🏗️ Architecture

```
VPC Network (10.0.0.0/16)
├── Public Subnet (10.0.1.0/24)
│   ├── GKE Clusters
│   ├── Load Balancers
│   └── Bastion Hosts
├── Private Subnet (10.0.2.0/24)
│   ├── CloudSQL Instances
│   ├── Private Services
│   └── Internal Applications
└── Secondary IP Ranges
    ├── Pod Range (10.1.0.0/16)
    └── Service Range (10.2.0.0/20)
```

## 📋 Features

- ✅ **VPC-native networking** for optimal GKE performance
- ✅ **Private Google Access** for secure API calls
- ✅ **NAT Gateway** for internet access from private subnet
- ✅ **Comprehensive firewall rules** with least-privilege access
- ✅ **Flow logs** for network monitoring and troubleshooting
- ✅ **Secondary IP ranges** for GKE pods and services

## 🔧 Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  # Required variables
  project_id  = "my-gcp-project"
  region      = "us-central1"
  environment = "dev"

  # Optional customization
  vpc_name             = "my-vpc"
  public_subnet_cidr   = "10.0.1.0/24"
  private_subnet_cidr  = "10.0.2.0/24"
  pod_cidr            = "10.1.0.0/16"
  service_cidr        = "10.2.0.0/20"
  
  # Security
  ssh_source_ranges = ["203.0.113.0/24"] # Your office IP
}
```

## 📥 Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | GCP project ID | string | n/a | yes |
| region | GCP region | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| vpc_name | VPC network name | string | "devops-vpc" | no |
| public_subnet_cidr | Public subnet CIDR | string | "10.0.1.0/24" | no |
| private_subnet_cidr | Private subnet CIDR | string | "10.0.2.0/24" | no |

## 📤 Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC network |
| public_subnet_self_link | Public subnet self-link for GKE |
| private_subnet_self_link | Private subnet self-link for CloudSQL |
| gke_network_config | Network configuration for GKE module |
| cloudsql_network_config | Network configuration for CloudSQL module |

## 🔒 Security Features

### Firewall Rules
- **Internal**: Allows all traffic within VPC
- **SSH**: Restricted SSH access with source IP filtering
- **Web**: HTTP/HTTPS traffic to web-tagged instances
- **GKE**: Master-to-node communication
- **Health Checks**: Google Cloud Load Balancer health checks

### Network Segmentation
- **Public Subnet**: Internet-facing resources
- **Private Subnet**: Internal resources with no direct internet access
- **Secondary Ranges**: Dedicated IP space for Kubernetes pods and services

## 🏷️ Tagging Strategy

Resources are tagged for:
- **Network security** (firewall rule targeting)
- **Cost allocation** (environment-based billing)
- **Compliance** (resource classification)

Common tags:
- `gke-node`: GKE worker nodes
- `web`: Web servers and load balancers
- `ssh`: SSH-accessible instances

## 📊 Cost Optimization

- **NAT Gateway**: Configured with optimal port allocation
- **Flow Logs**: Sampling rate adjustable for cost control
- **Regional Resources**: Single-region deployment reduces data transfer costs

## 🚀 Version History

- **v1.0.0**: Initial release with basic VPC, subnets, and firewall rules
- **v1.1.0**: Added flow logs and enhanced security rules
- **v1.2.0**: Optimized for GKE VPC-native networking

## 🔗 Related Modules

This VPC module works with:
- [GKE Module](../gke/) - Uses `gke_network_config` output
- [CloudSQL Module](../cloudsql/) - Uses `cloudsql_network_config` output