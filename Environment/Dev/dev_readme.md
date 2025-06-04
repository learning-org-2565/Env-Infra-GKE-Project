# Development Environment

## 🧪 Overview

This is the **development environment** configuration that creates a complete, cost-optimized infrastructure stack using our custom Terraform modules. Perfect for learning, testing, and development workflows.

## 🏗️ What Gets Created

```
Development Environment
├── 🌐 VPC Network (dev-vpc)
│   ├── Public Subnet (10.10.1.0/24)
│   ├── Private Subnet (10.10.2.0/24)
│   ├── Pod Range (10.11.0.0/16)
│   └── Service Range (10.12.0.0/20)
├── ⚓ GKE Cluster (dev-cluster)
│   ├── 1x e2-micro node (spot instance)
│   ├── 50GB standard disk
│   └── Public endpoint for easy access
└── 🗃️ CloudSQL PostgreSQL (dev-postgres)
    ├── db-f1-micro instance
    ├── 10GB SSD storage
    ├── No backups (cost optimization)
    └── Private networking only
```

## 💰 Cost Optimization

**Estimated Monthly Cost: $15-60**

### Cost-Saving Features
- ✅ **Spot instances**: 60-80% savings on compute
- ✅ **Minimal sizing**: e2-micro + db-f1-micro
- ✅ **Single zone**: No cross-zone charges
- ✅ **No backups**: Disabled for dev cost savings
- ✅ **Standard disks**: Cheaper storage option

### Optional Cost Optimization
- 🕐 **Auto-shutdown**: Weekdays 6 PM - 8 AM (70% additional savings)
- 🔄 **Delete when unused**: 100% savings

## 🚀 Quick Start

### Prerequisites
```bash
# Required tools
- gcloud CLI (authenticated)
- terraform >= 1.0
- kubectl
- git

# Verify authentication
gcloud auth list
gcloud config get-value project
```

### Step 1: Clone and Setup
```bash
# Clone your infrastructure repository
git clone https://github.com/yourorg/terraform-gcp-infrastructure.git
cd terraform-gcp-infrastructure/environments/dev

# Update terraform.tfvars with your project ID
vim terraform.tfvars
# Change: project_id = "your-actual-project-id"
```

### Step 2: Create State Bucket
```bash
# Create bucket for Terraform state (one-time setup)
gsutil mb gs://terraform-state-dev-YOUR-PROJECT-ID
gsutil versioning set on gs://terraform-state-dev-YOUR-PROJECT-ID

# Update backend config
vim backend-dev.tfbackend
# Change: bucket = "terraform-state-dev-YOUR-PROJECT-ID"
```

### Step 3: Deploy Infrastructure
```bash
# Initialize Terraform with backend
terraform init -backend-config=backend-dev.tfbackend

# Review what will be created
terraform plan -var-file="terraform.tfvars"

# Deploy the infrastructure
terraform apply -var-file="terraform.tfvars"
```

### Step 4: Configure kubectl
```bash
# Configure kubectl (use output from terraform)
terraform output kubectl_config_command
# Run the command it outputs, something like:
gcloud container clusters get-credentials dev-cluster --region us-central1 --project YOUR-PROJECT

# Verify cluster access
kubectl get nodes
kubectl get namespaces
```

### Step 5: Verify Setup
```bash
# Check all resources are ready
kubectl get all --all-namespaces

# View development information
kubectl get configmap dev-environment-info -o yaml

# Check database secret
kubectl get secret cloudsql-credentials -o yaml
```

## 🔧 Development Workflow

### Deploying Applications

#### Method 1: Using Cloud SQL Proxy (Recommended)
```yaml
# example-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      # Your application
      - name: app
        image: your-app:latest
        env:
        - name: DB_HOST
          value: "127.0.0.1"  # Connect to proxy
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          valueFrom:
            secretKeyRef:
              name: cloudsql-credentials
              key: DB_NAME
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: cloudsql-credentials
              key: DB_USER
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: cloudsql-credentials
              key: DB_PASSWORD
      
      # Cloud SQL Proxy sidecar
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
              name: cloudsql-credentials
              key: INSTANCE_CONNECTION_NAME
        - name: GOOGLE_APPLICATION_CREDENTIALS
          value: /secrets/service-account.json
        volumeMounts:
        - name: cloudsql-key
          mountPath: /secrets
          readOnly: true
      
      volumes:
      - name: cloudsql-key
        secret:
          secretName: cloudsql-proxy-key
```

#### Method 2: Direct Private IP (Advanced)
```yaml
# Direct connection using private IP
env:
- name: DB_HOST
  valueFrom:
    secretKeyRef:
      name: cloudsql-credentials
      key: DB_HOST  # Private IP of CloudSQL
```

### Database Management

#### Connect to Database
```bash
# Method 1: Using Cloud SQL Proxy
cloud_sql_proxy -instances=$(terraform output -raw cloudsql_info | jq -r '.connection_name')=tcp:5432 &
psql -h 127.0.0.1 -p 5432 -U $(kubectl get secret cloudsql-credentials -o jsonpath='{.data.DB_USER}' | base64 -d) -d $(kubectl get secret cloudsql-credentials -o jsonpath='{.data.DB_NAME}' | base64 -d)

# Method 2: From inside cluster
kubectl run postgres-client --rm -i --tty --image postgres:15 -- bash
# Inside the pod:
psql -h PRIVATE_IP -U USERNAME -d DATABASE_NAME
```

#### Database Operations
```bash
# Get database password
kubectl get secret cloudsql-credentials -o jsonpath='{.data.DB_PASSWORD}' | base64 -d

# Create tables (example)
kubectl exec -it deploy/my-app -- psql $DATABASE_URL -c "
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"
```

## 📊 Monitoring and Debugging

### Cluster Health
```bash
# Check cluster status
kubectl get componentstatuses
kubectl get nodes -o wide
kubectl top nodes

# Check resource usage
kubectl top pods --all-namespaces
kubectl describe nodes
```

### Application Debugging
```bash
# View pod logs
kubectl logs -f deployment/my-app -c app
kubectl logs -f deployment/my-app -c cloudsql-proxy

# Debug pod issues
kubectl describe pod POD_NAME
kubectl get events --sort-by='.lastTimestamp'

# Connect to pod for debugging
kubectl exec -it deployment/my-app -c app -- sh
```

### Database Debugging
```bash
# Check CloudSQL status
gcloud sql instances describe $(terraform output -raw cloudsql_info | jq -r '.instance_name')

# View database logs
gcloud sql instances describe $(terraform output -raw cloudsql_info | jq -r '.instance_name') --log-filters="severity>=ERROR"

# Test connectivity
kubectl run netshoot --rm -i --tty --image nicolaka/netshoot -- bash
# Inside pod: nc -zv PRIVATE_IP 5432
```

## 🔒 Security Notes

### Current Security Posture (Development)
- ✅ **Private CloudSQL**: No public internet access
- ✅ **Kubernetes secrets**: Credentials stored securely
- ✅ **Service accounts**: Proper authentication
- ⚠️ **Public GKE nodes**: For easier development access
- ⚠️ **Open SSH**: From anywhere (development convenience)
- ⚠️ **No SSL requirement**: Simplified database connections

### Security Improvements for Production
```bash
# 1. Private GKE nodes
enable_private_nodes = true
enable_private_endpoint = true

# 2. Restricted SSH access
ssh_source_ranges = ["YOUR.OFFICE.IP.RANGE/24"]

# 3. SSL for database
require_ssl = true
create_ssl_cert = true

# 4. Additional security features
enable_network_policy = true
enable_pod_security_policy = true
```

## 💡 Tips and Tricks

### Development Workflow
```bash
# Hot reload setup (example with Skaffold)
skaffold dev --port-forward

# Quick database schema updates
kubectl create job schema-update --from=cronjob/my-migration-job

# Debug networking
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- bash
```

### Cost Management
```bash
# Check current costs
gcloud billing projects describe $(terraform output -raw environment_summary | jq -r '.project_id')

# Set up billing alerts
gcloud alpha billing budgets create \
  --billing-account=YOUR_BILLING_ACCOUNT \
  --display-name="Dev Environment Alert" \
  --budget-amount=50 \
  --threshold-rule=percent=80

# Auto-shutdown script (optional)
# Add to crontab: 0 18 * * 1-5 /path/to/shutdown-dev.sh
```

### Backup Important Data
```bash
# Even though backups are disabled, backup important dev data
kubectl create job manual-backup --from=cronjob/database-backup

# Export configurations
kubectl get configmaps,secrets -o yaml > dev-configs-backup.yaml
```

## 🚨 Troubleshooting

### Common Issues

#### "Insufficient resources"
```bash
# Problem: e2-micro is very small
# Solution: Either reduce resource requests or upgrade instance
# Quick fix: Delete unused pods
kubectl delete pod --all --grace-period=0 --force -n default
```

#### "Can't connect to database"
```bash
# Check secret exists
kubectl get secret cloudsql-credentials

# Verify proxy is running
kubectl logs deployment/my-app -c cloudsql-proxy

# Test connectivity
kubectl exec deployment/my-app -c app -- nc -zv 127.0.0.1 5432
```

#### "Spot instance preempted"
```bash
# This is normal! Check pod status
kubectl get pods -o wide

# Pods should reschedule automatically
kubectl describe pod POD_NAME
```

#### "Out of disk space"
```bash
# Check disk usage
kubectl exec -it deployment/my-app -- df -h

# Clean up if needed
kubectl exec -it deployment/my-app -- rm -rf /tmp/*
```

### Getting Help
```bash
# View all troubleshooting info
terraform output troubleshooting

# Check Terraform outputs
terraform output
terraform output next_steps
```

## 🧹 Cleanup

### Destroy Environment
```bash
# Destroy all resources
terraform destroy -var-file="terraform.tfvars"

# Clean up state bucket (optional)
gsutil rm -r gs://terraform-state-dev-YOUR-PROJECT-ID
```

### Partial Cleanup
```bash
# Remove just the expensive parts
terraform destroy -target=module.gke -var-file="terraform.tfvars"
terraform destroy -target=module.cloudsql -var-file="terraform.tfvars"
# Keep VPC for next time
```

## 📚 Learning Resources

### Next Steps
1. **Deploy a real application** using the examples above
2. **Set up CI/CD pipeline** to deploy to this environment
3. **Learn Kubernetes concepts** with this working cluster
4. **Experiment with scaling** and resource management
5. **Create production environment** with enhanced security

### Related Documentation
- [VPC Module Documentation](../../modules/vpc/README.md)
- [GKE Module Documentation](../../modules/gke/README.md)
- [CloudSQL Module Documentation](../../modules/cloudsql/README.md)
- [Production Environment Setup](../prod/README.md)

---

**Happy Learning! 🚀**

This development environment is designed to be:
- **Cost-effective** for learning and experimentation
- **Easy to use** with sensible defaults
- **Realistic** enough to learn production concepts
- **Safe to break** and rebuild quickly