# Production Environment

## 🚀 Overview

This is the **production environment** configuration that creates an enterprise-grade, highly available, security-hardened infrastructure stack using our custom Terraform modules. Designed for critical business applications with strict SLA, compliance, and security requirements.

## 🏗️ What Gets Created

```
Production Environment
├── 🌐 VPC Network (enterprise-vpc)
│   ├── Public Subnet (10.20.1.0/24)
│   ├── Private Subnet (10.20.2.0/24)
│   ├── Pod Range (10.21.0.0/16) - 65k IPs
│   └── Service Range (10.22.0.0/20) - 4k IPs
├── ⚓ GKE Cluster (enterprise-cluster)
│   ├── 3-30 nodes across 3 zones (e2-standard-4)
│   ├── High-memory pool (n2-highmem-4)
│   ├── Private nodes with customer-managed encryption
│   └── Auto-scaling, auto-repair, auto-upgrade
└── 🗃️ CloudSQL PostgreSQL (enterprise-postgres)
    ├── db-custom-4-15360 (4 vCPU, 15GB RAM)
    ├── 500GB SSD storage
    ├── Regional deployment (HA)
    ├── Read replica in us-west1
    ├── 30-day backup retention
    └── SSL + IAM authentication
```

## 📊 Production vs Development Comparison

| Feature | Development | Production | Why Different |
|---------|-------------|------------|---------------|
| **Cost** | $15-60/month | $1,500-2,000/month | Enterprise scale & features |
| **Availability** | Single zone | Multi-zone regional | 99.99% uptime SLA |
| **Security** | Relaxed access | Hardened (private endpoints) | Compliance requirements |
| **Scaling** | 1 fixed node | 3-30 auto-scaling nodes | Handle production load |
| **Database** | db-f1-micro, no backups | db-custom-4-15360, daily backups | Performance & durability |
| **Monitoring** | Basic | Comprehensive + alerting | Proactive issue detection |
| **Encryption** | Standard | Customer-managed keys | Data protection compliance |
| **Disaster Recovery** | None | Cross-region replicas | Business continuity |

## 🔒 Enterprise Security Features

### Network Security
- ✅ **Private GKE nodes** - No public IPs on worker nodes
- ✅ **Restricted SSH access** - Office/VPN IP ranges only
- ✅ **Network policies** - Micro-segmentation within cluster
- ✅ **VPC-native networking** - Optimal security and performance
- ✅ **Private CloudSQL** - Database accessible only from VPC

### Encryption & Key Management
- ✅ **Customer-managed encryption** - KMS keys for GKE database encryption
- ✅ **SSL/TLS everywhere** - All database connections encrypted
- ✅ **Backup encryption** - Encrypted backups with rotation
- ✅ **Key rotation** - Automatic 90-day rotation cycle

### Access Control
- ✅ **IAM database authentication** - No shared passwords
- ✅ **Workload Identity** - Secure pod-to-GCP authentication
- ✅ **RBAC** - Role-based access control in Kubernetes
- ✅ **Resource quotas** - Prevent resource exhaustion

### Compliance & Auditing
- ✅ **Comprehensive audit logs** - All actions logged
- ✅ **Performance monitoring** - Full observability stack
- ✅ **Security monitoring** - Threat detection and alerting
- ✅ **Backup verification** - Regular restore testing

## 🚀 Deployment Guide

### Prerequisites

#### Required Tools
```bash
# Verify required tools
gcloud --version     # Google Cloud CLI
terraform --version  # Terraform >= 1.0
kubectl version      # Kubernetes CLI
```

#### Required Permissions
```bash
# Your service account needs these roles:
- Compute Admin
- Kubernetes Engine Admin
- Cloud SQL Admin
- IAM Admin
- Security Admin
- Monitoring Admin
```

#### Required APIs
```bash
# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable monitoring.googleapis.com
```

### Step 1: Environment Preparation

```bash
# Clone infrastructure repository
git clone https://github.com/yourorg/terraform-gcp-infrastructure.git
cd terraform-gcp-infrastructure/environments/prod

# Create production state bucket (one-time setup)
gsutil mb gs://terraform-state-prod-YOUR-PROJECT-ID
gsutil versioning set on gs://terraform-state-prod-YOUR-PROJECT-ID

# Update backend configuration
vim backend-prod.tfbackend
# bucket = "terraform-state-prod-YOUR-PROJECT-ID"
```

### Step 2: Configuration

```bash
# Update production values
vim terraform.tfvars

# CRITICAL: Update these values:
# - project_id = "your-actual-prod-project"
# - ssh_source_ranges = ["YOUR.OFFICE.IP.RANGE/24"]
# - notification_channels = ["your-actual-channel-ids"]
# - Support contact emails
```

### Step 3: Security Review

```bash
# Review security configuration
grep -E "(ssh_source_ranges|authorized_networks)" terraform.tfvars
grep -E "(enable_private|require_ssl)" terraform.tfvars

# Verify no 0.0.0.0/0 in SSH ranges
# Verify notification channels are configured
# Verify support contacts are correct
```

### Step 4: Deployment

```bash
# Initialize Terraform
terraform init -backend-config=backend-prod.tfbackend

# Plan deployment (review carefully!)
terraform plan -var-file="terraform.tfvars" -out=prod.tfplan

# Apply after thorough review
terraform apply prod.tfplan
```

### Step 5: Post-Deployment Verification

```bash
# Configure kubectl
terraform output -raw kubectl_config | bash

# Verify cluster health
kubectl get nodes
kubectl get componentstatuses

# Check namespace creation
kubectl get namespaces

# Verify secrets
kubectl get secrets -n production

# Test database connectivity
kubectl run db-test --rm -i --tty --image postgres:15 -- bash
# Inside pod: psql -h PRIVATE_IP -U USERNAME -d DATABASE
```

## 🔧 Production Operations

### Application Deployment

#### Production-Grade Deployment Example
```yaml
# production-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: production
  labels:
    app: my-app
    tier: critical
    version: v1.0.0
spec:
  replicas: 3  # High availability
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
        tier: critical
    spec:
      serviceAccountName: backend-sa  # Workload Identity
      
      # Anti-affinity for high availability
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - my-app
              topologyKey: kubernetes.io/hostname
      
      containers:
      # Main application container
      - name: app
        image: your-app:v1.0.0
        ports:
        - containerPort: 3000
          name: http
        
        # Environment from secrets
        env:
        - name: DB_HOST
          value: "127.0.0.1"  # Cloud SQL Proxy
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
        
        # Resource limits (required in production)
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        
        # Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        # Security context
        securityContext:
          runAsNonRoot: true
          runAsUser: 65534
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
      
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
        
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
        
        securityContext:
          runAsNonRoot: true
          runAsUser: 65532
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
      
      volumes:
      - name: cloudsql-key
        secret:
          secretName: cloudsql-proxy-key

---
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  namespace: production
  labels:
    app: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 3000
    name: http
  type: ClusterIP

---
# Horizontal Pod Autoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Database Operations

#### Connect to Production Database
```bash
# Using Cloud SQL Proxy (recommended)
cloud_sql_proxy -instances=$(terraform output -raw cloudsql_configuration | jq -r '.instance_name')=tcp:5432 &

# Connect with SSL (production requirement)
psql "sslmode=require host=127.0.0.1 port=5432 user=USERNAME dbname=DATABASE"

# Or via kubectl port-forward
kubectl port-forward svc/cloudsql-proxy 5432:5432 -n production
```

#### Database Maintenance
```bash
# Check database performance
psql -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"
psql -c "SELECT schemaname,tablename,attname,avg_width,n_distinct FROM pg_stats;"

# Monitor slow queries
psql -c "SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"

# Check connection count
psql -c "SELECT count(*) FROM pg_stat_activity;"
```

## 📊 Monitoring and Alerting

### Key Metrics to Monitor

#### Cluster Health
```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods --all-namespaces

# Cluster events
kubectl get events --sort-by=.metadata.creationTimestamp --all-namespaces

# Check cluster autoscaler
kubectl logs -n kube-system deployment/cluster-autoscaler
```

#### Database Performance
```bash
# CloudSQL metrics in GCP Console
# - CPU utilization (target: < 80%)
# - Memory utilization (target: < 80%)
# - Connection count (target: < 80% of max)
# - Disk utilization (target: < 80%)

# Query performance
psql -c "SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

#### Application Metrics
```bash
# Application logs
kubectl logs -f deployment/my-app -c app -n production

# Error rates
kubectl logs deployment/my-app -n production | grep ERROR | wc -l

# Response times (if using service mesh)
kubectl logs -f istio-proxy -c istio-proxy
```

### Alerting Policies

Production environment includes these critical alerts:
- **Cluster Down** - GKE cluster unreachable
- **High CPU Usage** - Node CPU > 80% for 5 minutes
- **High Memory Usage** - Node memory > 85% for 5 minutes
- **Pod Restart Loop** - Pod restarting > 3 times in 10 minutes
- **Database Down** - CloudSQL instance unreachable
- **Database High CPU** - CloudSQL CPU > 80% for 5 minutes
- **Backup Failure** - Automated backup failed
- **SSL Certificate Expiry** - Certificate expires in < 30 days

## 🚨 Incident Response

### Severity Levels

| Severity | Description | Response Time | Examples |
|----------|-------------|---------------|----------|
| **P1** | Critical system down | 15 minutes | Cluster down, database down |
| **P2** | Major functionality impacted | 1 hour | High error rates, slow performance |
| **P3** | Minor functionality impacted | 4 hours | Single pod failing, non-critical alerts |
| **P4** | Enhancement/maintenance | Next business day | Monitoring improvements |

### Emergency Procedures

#### Cluster Down
```bash
# 1. Check cluster status
gcloud container clusters describe CLUSTER_NAME --region REGION

# 2. Check node pool status
gcloud container node-pools list --cluster CLUSTER_NAME --region REGION

# 3. Scale up if needed
gcloud container clusters resize CLUSTER_NAME --num-nodes 3 --region REGION

# 4. Check for resource exhaustion
kubectl describe nodes
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### Database Issues
```bash
# 1. Check CloudSQL status
gcloud sql instances describe INSTANCE_NAME

# 2. Check connections
gcloud sql operations list --instance INSTANCE_NAME --limit 10

# 3. Failover to replica if needed
gcloud sql instances promote-replica REPLICA_NAME

# 4. Check backup status
gcloud sql backups list --instance INSTANCE_NAME
```

#### Security Incident
```bash
# 1. Isolate affected resources
kubectl cordon NODE_NAME
kubectl drain NODE_NAME --ignore-daemonsets

# 2. Preserve evidence
kubectl logs POD_NAME > incident-logs-$(date +%Y%m%d-%H%M%S).log

# 3. Check audit logs
gcloud logging read 'protoPayload.serviceName="cloudaudit.googleapis.com"'

# 4. Notify security team immediately
```

## 💰 Cost Management

### Cost Optimization Strategies

#### Committed Use Discounts
- **1-year commitment**: 20% discount
- **3-year commitment**: 30% discount
- Apply to: GKE nodes, CloudSQL instances

#### Resource Optimization
```bash
# Right-size based on actual usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check for unused resources
kubectl get pods --all-namespaces | grep "0/1\|0/2\|0/3"

# Review resource requests/limits
kubectl describe pods -n production | grep -A 5 "Requests\|Limits"
```

#### Storage Optimization
```bash
# Clean up old images
gcloud container images list-tags IMAGE_NAME --limit=999999 --sort-by=TIMESTAMP

# Optimize database storage
psql -c "SELECT schemaname,tablename,pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size FROM pg_tables ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10;"
```

### Monthly Cost Breakdown
- **GKE Compute**: $400-800/month (depends on scaling)
- **GKE Management**: $73/month (fixed)
- **CloudSQL Primary**: $350/month
- **CloudSQL Replica**: $175/month  
- **Storage**: $200-300/month
- **Networking**: $70-100/month
- **KMS Operations**: $10/month
- **Monitoring**: $50-100/month

**Total**: $1,500-2,000/month

## 📋 Compliance and Governance

### Audit Requirements
- **Access logs**: All kubectl and database access logged
- **Change tracking**: All infrastructure changes in Git
- **Resource history**: Terraform state versioning
- **Security events**: Comprehensive security monitoring

### Data Protection
- **Encryption in transit**: All connections use SSL/TLS
- **Encryption at rest**: Customer-managed keys
- **Backup encryption**: Encrypted with rotation
- **Key management**: 90-day rotation cycle

### Access Control
- **Principle of least privilege**: Minimal required permissions
- **Multi-factor authentication**: Required for all human access
- **Service account keys**: Automated rotation
- **Regular access review**: Quarterly access audits

## 🔧 Maintenance and Updates

### Scheduled Maintenance Windows
- **GKE maintenance**: Sundays 2-6 AM UTC
- **CloudSQL maintenance**: Sundays 3-4 AM UTC
- **Network maintenance**: Coordinated with vendors

### Update Procedures
```bash
# GKE cluster updates (automated within maintenance window)
gcloud container clusters update CLUSTER_NAME --enable-autoupgrade

# Node pool updates (automated)
gcloud container node-pools update POOL_NAME --enable-autoupgrade

# Database minor version updates (automated)
# Major version updates require manual approval
```

## 📚 Documentation and Runbooks

### Required Documentation
- ✅ **Architecture diagrams** - Current and up-to-date
- ✅ **Network topology** - VPC, subnets, firewall rules
- ✅ **Security model** - Access controls and encryption
- ✅ **Monitoring setup** - Alerts and dashboards
- ✅ **Backup procedures** - Recovery testing schedule
- ✅ **Incident response** - Contact information and procedures

### Operational Runbooks
- **Cluster scaling procedures**
- **Database failover procedures**  
- **Backup and restore procedures**
- **Security incident response**
- **Performance troubleshooting**
- **Cost optimization procedures**

---

## 🚀 Production Success Checklist

### Pre-Go-Live
- [ ] Security review completed
- [ ] Performance testing passed
- [ ] Backup/restore procedures tested
- [ ] Monitoring and alerting configured
- [ ] Incident response procedures documented
- [ ] Team training completed
- [ ] Support contacts updated

### Post-Go-Live
- [ ] Monitor performance metrics
- [ ] Verify backup schedules
- [ ] Test alert delivery
- [ ] Review cost optimization
- [ ] Update documentation
- [ ] Schedule regular reviews

**Your production environment is now enterprise-ready!** 🎉

This production setup provides:
- **99.99% availability** through multi-zone deployment
- **Enterprise security** with encryption and access controls
- **Scalability** from 3 to 30+ nodes automatically
- **Disaster recovery** with cross-region replicas
- **Compliance-ready** audit logging and monitoring

For additional support, contact the platform team or refer to the troubleshooting guides above.