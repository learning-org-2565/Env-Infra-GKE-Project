# CloudSQL Module

## 🗃️ Overview

This module creates a production-ready PostgreSQL CloudSQL instance with environment-specific configurations, private networking, automated backups, and comprehensive security features. It's designed to integrate seamlessly with GKE workloads while maintaining enterprise-grade security and reliability.

## 🏗️ Architecture

```
CloudSQL Instance
├── Private Networking
│   ├── VPC Peering
│   ├── Private IP Range
│   └── Firewall Rules
├── Security Features
│   ├── SSL/TLS Encryption
│   ├── IAM Authentication
│   ├── Secret Manager Integration
│   └── Audit Logging
├── High Availability (Prod)
│   ├── Regional Instance
│   ├── Read Replicas
│   └── Automated Backups
└── Monitoring & Alerting
    ├── Query Insights
    ├── Uptime Checks
    └── Custom Alerts
```

## 📋 Features

### Core Features
- ✅ **PostgreSQL 15** with automatic minor version updates
- ✅ **Private networking** with VPC peering
- ✅ **Automated backups** with point-in-time recovery
- ✅ **SSL/TLS encryption** for secure connections
- ✅ **Random password generation** with Secret Manager storage
- ✅ **Query insights** for performance monitoring

### Environment-Specific Features
- ✅ **Dev**: Small instance, basic backups, cost-optimized
- ✅ **Prod**: High availability, read replicas, encryption
- ✅ **Prod**: Maintenance windows, audit logging
- ✅ **Prod**: IAM authentication, password rotation

### Security Features
- ✅ **Private IP only** (no public internet access)
- ✅ **IAM database authentication** for service accounts
- ✅ **Customer-managed encryption** for backups (prod)
- ✅ **Network policies** for Kubernetes integration
- ✅ **Audit logging** for compliance requirements

## 🔧 Usage

### Basic Usage with VPC Module
```hcl
module "cloudsql" {
  source = "./modules/cloudsql"

  # Required variables
  project_id   = "my-gcp-project"
  region      = "us-central1"
  environment = "dev"
  instance_name = "my-app-db"

  # Network configuration (from VPC module)
  network_id        = module.vpc.vpc_id
  network_name      = module.vpc.vpc_name
  network_self_link = module.vpc.vpc_self_link

  # Database configuration
  database_name = "my_app"
  app_user_name = "app_user"
}
```

### Development Environment
```hcl
module "cloudsql_dev" {
  source = "./modules/cloudsql"

  project_id   = "my-project"
  region      = "us-central1"
  environment = "dev"
  instance_name = "dev-app-db"

  # Dev-specific settings
  tier                = "db-f1-micro"
  disk_size_gb       = 10
  disk_type          = "PD_SSD"
  availability_type  = "ZONAL"
  
  # Backup settings (minimal for dev)
  backup_enabled               = false
  point_in_time_recovery_enabled = false
  deletion_protection         = false
  
  # Network from VPC module
  network_id        = module.vpc.vpc_id
  network_name      = module.vpc.vpc_name
  network_self_link = module.vpc.vpc_self_link
  
  # Allow access from GKE
  allowed_source_ranges = [
    module.vpc.pod_cidr,
    module.vpc.service_cidr
  ]
}
```

### Production Environment
```hcl
module "cloudsql_prod" {
  source = "./modules/cloudsql"

  project_id   = "my-project"
  region      = "us-central1"
  environment = "prod"
  instance_name = "prod-app-db"

  # Prod-specific settings
  tier                = "db-custom-4-15360"  # 4 vCPU, 15GB RAM
  disk_size_gb       = 100
  disk_type          = "PD_SSD"
  availability_type  = "REGIONAL"  # High availability
  deletion_protection = true
  
  # Advanced backup configuration
  backup_enabled                 = true
  backup_start_time             = "02:00"
  point_in_time_recovery_enabled = true
  backup_retained_backups       = 30
  transaction_log_retention_days = 7
  
  # Read replica for performance
  enable_read_replica    = true
  replica_region        = "us-west1"
  replica_tier          = "db-custom-2-7680"
  
  # Security features
  require_ssl                           = true
  enable_iam_auth                      = true
  enable_backup_encryption             = true
  store_passwords_in_secret_manager    = true
  enable_password_rotation             = true
  password_rotation_days               = 90
  
  # Maintenance window
  maintenance_window_day  = 7  # Sunday
  maintenance_window_hour = 3  # 3 AM
  
  # Monitoring and alerting
  enable_uptime_checks = true
  enable_alerting     = true
  enable_audit_logs   = true
  
  # Network from VPC module
  network_id        = module.vpc.vpc_id
  network_name      = module.vpc.vpc_name
  network_self_link = module.vpc.vpc_self_link
}
```

### Integration with GKE
```hcl
# Use CloudSQL outputs in GKE deployment
resource "kubernetes_secret" "database_credentials" {
  metadata {
    name      = "database-credentials"
    namespace = "default"
  }

  # Use CloudSQL module outputs
  data = module.cloudsql.kubernetes_secret_data

  type = "Opaque"
}
```

## 📥 Inputs

### Required Inputs
| Name | Description | Type | Required |
|------|-------------|------|----------|
| project_id | GCP project ID | string | yes |
| region | GCP region | string | yes |
| environment | Environment (dev/staging/prod) | string | yes |
| instance_name | CloudSQL instance name | string | yes |
| network_id | VPC network ID | string | yes |
| network_name | VPC network name | string | yes |
| network_self_link | VPC network self-link | string | yes |

### Environment-Specific Defaults
| Setting | Dev Default | Prod Default |
|---------|-------------|--------------|
| tier | db-f1-micro | db-custom-4-15360 |
| disk_size_gb | 10 | 100 |
| availability_type | ZONAL | REGIONAL |
| backup_enabled | false | true |
| deletion_protection | false | true |
| read_replica | false | available |

## 📤 Outputs

### Connection Information
| Name | Description |
|------|-------------|
| connection_name | Cloud SQL Proxy connection name |
| private_ip_address | Private IP address |
| connection_string_proxy | Connection string for proxy |
| proxy_connection_config | Complete proxy configuration |

### Credentials (Sensitive)
| Name | Description |
|------|-------------|
| app_user_password | Application user password |
| postgres_password | Admin user password |
| kubernetes_secret_data | Base64-encoded data for K8s secrets |

### Configuration Details
| Name | Description |
|------|-------------|
| database_name | Main database name |
| environment_config | Environment-specific settings |
| backup_configuration | Backup settings summary |

## 🔒 Security Features

### Network Security
- **Private IP only**: No direct internet access
- **VPC peering**: Secure connection to application VPC
- **Firewall rules**: Restricted access from authorized sources
- **Network policies**: Kubernetes-level access control

### Authentication & Authorization
- **IAM database authentication**: Service account-based access
- **Strong passwords**: Auto-generated with special characters
- **Secret Manager**: Secure password storage
- **SSL/TLS**: Encrypted connections required

### Data Protection
- **Encryption in transit**: SSL/TLS connections
- **Encryption at rest**: Automatic disk encryption
- **Backup encryption**: Customer-managed keys (prod)
- **Audit logging**: Comprehensive activity tracking

### Access Control
- **Principle of least privilege**: Minimal required permissions
- **Password rotation**: Automatic rotation (prod)
- **Certificate management**: SSL client certificates
- **Connection limits**: Prevent resource exhaustion

## 📊 Environment Differences

### Development Environment
- **Cost-optimized**: Minimal instance size and features
- **Simplified setup**: Basic configuration for development
- **No high availability**: Single-zone deployment
- **Minimal backups**: Disabled for cost savings

### Production Environment
- **High availability**: Regional deployment with read replicas
- **Enhanced security**: IAM auth, encryption, audit logs
- **Comprehensive backups**: Point-in-time recovery, retention
- **Maintenance windows**: Scheduled updates during off-hours
- **Monitoring & alerting**: Proactive issue detection

## 🚀 Integration Examples

### Cloud SQL Proxy Sidecar
```yaml
# Kubernetes deployment with Cloud SQL Proxy
spec:
  containers:
  - name: app
    image: my-app:latest
    env:
    - name: DB_HOST
      value: "127.0.0.1"
    - name: DB_PORT
      value: "5432"
    - name: DB_NAME
      valueFrom:
        secretKeyRef:
          name: database-credentials
          key: DB_NAME
  
  - name: cloudsql-proxy
    image: gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.8.0
    args:
      - "--structured-logs"
      - "--port=5432"
      - "$(INSTANCE_CONNECTION_NAME)"
    env:
    - name: INSTANCE_CONNECTION_NAME
      valueFrom:
        secretKeyRef:
          name: database-credentials
          key: INSTANCE_CONNECTION_NAME
```

### Direct Private Connection
```yaml
# Direct connection using private IP
spec:
  containers:
  - name: app
    image: my-app:latest
    env:
    - name: DB_HOST
      valueFrom:
        secretKeyRef:
          name: database-credentials
          key: DB_HOST
    - name: DB_CONNECTION_STRING
      valueFrom:
        secretKeyRef:
          name: database-credentials
          key: DB_CONNECTION_STRING
```

## 💰 Cost Optimization

### Development
- **Micro instances**: db-f1-micro for minimal cost
- **Disabled backups**: Reduce storage costs
- **Single zone**: No cross-zone data transfer
- **HDD storage**: Lower cost for non-critical data

### Production
- **Right-sizing**: Monitor and adjust instance size
- **Read replicas**: Optimize for read-heavy workloads
- **Backup retention**: Balance protection vs. cost
- **Committed use**: Discounts for predictable workloads

## 🔧 Troubleshooting

### Common Issues

#### Connection Refused
```bash
# Check private IP connectivity
gcloud sql instances describe INSTANCE_NAME --format="value(ipAddresses)"

# Test from GKE pod
kubectl exec -it POD_NAME -- psql -h PRIVATE_IP -U USERNAME -d DATABASE
```

#### SSL Certificate Issues
```bash
# Download server CA certificate
gcloud sql instances describe INSTANCE_NAME \
  --format="value(serverCaCert.cert)" > server-ca.pem

# Verify SSL configuration
psql "sslmode=require sslcert=client-cert.pem sslkey=client-key.pem sslrootcert=server-ca.pem host=PRIVATE_IP user=USERNAME dbname=DATABASE"
```

#### Performance Issues
```bash
# Check query insights
gcloud sql instances describe INSTANCE_NAME --format="value(settings.insightsConfig)"

# Monitor connections
gcloud sql operations list --instance=INSTANCE_NAME --limit=10
```

## 📊 Monitoring

### Key Metrics
- **Connection count**: Monitor concurrent connections
- **CPU utilization**: Track instance performance
- **Memory usage**: Identify memory pressure
- **Disk I/O**: Monitor storage performance
- **Query performance**: Slow query identification

### Alerting Policies
- **Instance down**: Critical availability alert
- **High CPU**: Performance degradation warning
- **Connection limit**: Resource exhaustion alert
- **Backup failures**: Data protection issues

## 🏷️ Version History

- **v1.0.0**: Initial release with PostgreSQL 15
- **v1.1.0**: Added IAM authentication and read replicas
- **v1.2.0**: Enhanced security with Secret Manager integration
- **v1.3.0**: Production features: backup encryption, audit logs