# Module 1: Foundation Breaking - Terraform Core Destruction

## Scenario 1: State File Corruption Disaster

### Step 1: Break It
```bash
# Backup your working state first!
cp terraform.tfstate terraform.tfstate.backup

# Corrupt the state file
echo "corrupted state file" > terraform.tfstate

# Try to run terraform
terraform plan
```

### Step 2: What Breaks
```
Error: Failed to load state: state file is not valid JSON
Error: Unable to read state file
```

### Step 3: Fix It
```bash
# Restore from backup
cp terraform.tfstate.backup terraform.tfstate

# Verify it works
terraform plan
```

### Step 4: What You Learned
- State files are JSON and easily corrupted
- Always backup before major changes
- Remote state prevents this issue

---

## Scenario 2: Provider Version Hell

### Step 1: Break It
```hcl
# In providers.tf - Use incompatible version
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 2.0"  # Very old version
    }
  }
}
```

### Step 2: What Breaks
```
Error: Failed to install provider
Error: Incompatible provider version
```

### Step 3: Fix It
```bash
# Remove lock files
rm -rf .terraform .terraform.lock.hcl

# Fix version in providers.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0, < 6.0"
    }
  }
}

# Reinitialize
terraform init
```

### Step 4: What You Learned
- Provider versions must be compatible
- Lock files prevent version drift
- Always use version ranges, not exact versions

---

## Scenario 3: Variable Validation Explosion

### Step 1: Break It
```hcl
# In terraform.tfvars - Break all validations
project_id      = ""  # Empty string
region          = "invalid-region"
environment     = "development-environment-very-long"
gke_num_nodes   = 0   # Below minimum
gke_max_nodes   = 1000 # Above maximum
```

### Step 2: What Breaks
```
Error: Invalid value for variable "project_id"
Error: Invalid value for variable "region"
Error: Number of nodes must be between 1 and 10
```

### Step 3: Fix It
```hcl
# Fix terraform.tfvars
project_id      = "turnkey-guild-441104-f3"
region          = "us-central1"
environment     = "dev"
gke_num_nodes   = 1
gke_max_nodes   = 3
```

### Step 4: What You Learned
- Validation prevents invalid configurations
- Error messages should be helpful
- Type constraints are important

---

## Scenario 4: Resource Naming Collision

### Step 1: Break It
```hcl
# Create duplicate resource names
module "vpc_first" {
  source = "./modules/vpc"
  vpc_name = "duplicate-vpc"  # Same name
  # ... other config
}

module "vpc_second" {
  source = "./modules/vpc"
  vpc_name = "duplicate-vpc"  # Same name!
  # ... other config
}
```

### Step 2: What Breaks
```
Error: Error creating Network: googleapi: Error 409: 
The resource already exists
```

### Step 3: Fix It
```hcl
# Use unique names
module "vpc_first" {
  vpc_name = "dev-vpc-primary"
}

module "vpc_second" {
  vpc_name = "dev-vpc-secondary"
}
```

### Step 4: What You Learned
- Resource names must be unique in GCP
- Use systematic naming conventions
- Consider using random suffixes for uniqueness

---

## Scenario 5: Backend Configuration Disaster

### Step 1: Break It
```hcl
# Change backend to non-existent bucket
terraform {
  backend "gcs" {
    bucket = "non-existent-bucket-12345"
    prefix = "terraform/state/wrong-path"
  }
}
```

### Step 2: What Breaks
```
Error: Backend configuration changed
Error: Failed to get existing workspaces: storage: bucket doesn't exist
```

### Step 3: Fix It
```bash
# Fix backend configuration
terraform {
  backend "gcs" {
    bucket = "terraform-statefile-bucket-tf2"
    prefix = "terraform/state/vpc-gke-modules"
  }
}

# Reconfigure backend
terraform init -reconfigure
```

### Step 4: What You Learned
- Backend changes require reconfiguration
- Always verify bucket exists before changing backend
- Use consistent naming for state prefixes

---

## Scenario 6: Circular Dependency Hell

### Step 1: Break It
```hcl
# In modules/vpc/outputs.tf - Create circular dependency
output "gke_cluster_name" {
  value = var.gke_cluster_name  # VPC depends on GKE
}

# In main.tf
module "vpc" {
  gke_cluster_name = module.gke.cluster_name  # VPC needs GKE
}

module "gke" {
  vpc_network = module.vpc.vpc_self_link  # GKE needs VPC
}
```

### Step 2: What Breaks
```
Error: Cycle: module.vpc, module.gke
Error: Circular dependency between modules
```

### Step 3: Fix It
```hcl
# Remove circular dependency in modules/vpc/outputs.tf
# Delete the gke_cluster_name output

# In main.tf - Handle naming in root
locals {
  vpc_name = "${var.environment}-devops-vpc"
  gke_name = "${var.environment}-devops-gke"
}

module "vpc" {
  vpc_name = local.vpc_name
}

module "gke" {
  gke_cluster_name = local.gke_name
  vpc_network      = module.vpc.vpc_self_link
}
```

### Step 4: What You Learned
- Dependencies must be one-way
- Root module should orchestrate module interactions
- Use locals for shared naming patterns

---

## Your Assignment

1. **Try each scenario in order**
2. **Actually break your infrastructure** 
3. **Follow the fix steps**
4. **Document what you learned**
5. **Move to next scenario**

Take 1-2 scenarios per day. In 1 week you'll master Terraform fundamentals!

## Next: Module 2 - VPC Networking Disasters

Once you complete all Module 1 scenarios, I'll give you Module 2 with VPC and networking breaking scenarios.