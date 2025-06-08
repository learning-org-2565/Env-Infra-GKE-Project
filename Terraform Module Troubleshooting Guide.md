# Terraform Module Troubleshooting Guide
Great idea! Let's intentionally break the module and learn troubleshooting. Here are common failure scenarios you'll encounter:Now let's create some actual broken configurations you can test! Here are specific examples to copy-paste and break your working module:Here's a testing script to automate running through these failure scenarios:Perfect! Now you have a comprehensive troubleshooting guide. Here's how to use it:

## 🎯 **Quick Start - Break and Fix**

### **1. Run the Automated Test Script**
```bash
# Make script executable
chmod +x test_failure_scenarios.sh

# Run the automated tests
./test_failure_scenarios.sh
```

### **2. Manual Testing (Pick Any Scenario)**
```bash
# Test 1: Invalid Environment
echo 'environment = "development"' >> terraform.tfvars
terraform validate  # ❌ Should fail

# Fix and retest
sed -i 's/development/dev/' terraform.tfvars
terraform validate  # ✅ Should pass
```

## 🔧 **Essential Debug Commands**

### **During Each Failure:**
```bash
# Basic validation
terraform validate
terraform fmt -check

# Detailed planning with debug
export TF_LOG=DEBUG
terraform plan 2>&1 | tee debug.log

# Check what exists
terraform state list
gcloud compute networks list
```

### **Quick Recovery:**
```bash
# Reset everything
rm -rf .terraform .terraform.lock.hcl
terraform init
terraform plan

# Force unlock if needed
terraform force-unlock LOCK_ID
```

## 📚 **Learning Outcomes**

After running through these scenarios, you'll master:

✅ **Reading Terraform Error Messages** - Understanding what went wrong  
✅ **Variable Validation** - Why constraints matter  
✅ **Network Planning** - CIDR conflicts and resolution  
✅ **Module Architecture** - Source paths and dependencies  
✅ **Version Management** - Provider compatibility  
✅ **State Management** - Backend configuration issues  
✅ **Resource Conflicts** - Naming and duplication problems  

## 🚨 **Most Common Real-World Issues:**

1. **CIDR Overlaps** - Plan your IP space carefully
2. **Provider Versions** - Keep versions aligned
3. **Missing APIs** - Enable required GCP APIs first
4. **State Locks** - Multiple people working simultaneously
5. **Resource Names** - Ensure uniqueness across environments

## 💡 **Pro Tips:**

- **Always plan first**: `terraform plan` before `apply`
- **Use validation**: Add it to your CI/CD pipeline
- **Version everything**: Lock provider versions
- **Name systematically**: Use prefixes/suffixes for uniqueness
- **Test incrementally**: Small changes are easier to debug

Try running a few scenarios manually to get comfortable with the error messages and troubleshooting process. This hands-on experience will make you much more confident with Terraform in production! 🎯
## 🔥 Scenario 1: Variable Validation Failures

### **Break It:**
```hcl
# In terraform.tfvars - Invalid CIDR
project_id  = "your-project"
region      = "us-central1"
environment = "development"  # Invalid - not in allowed values

# Or in main.tf
module "vpc" {
  source = "./modules/vpc"
  
  public_subnet_cidr  = "not-a-cidr"     # Invalid CIDR
  private_subnet_cidr = "300.0.0.0/24"   # Invalid IP range
  environment         = "dev-env"        # Invalid environment
}
```

### **Error Messages:**
```bash
Error: Invalid value for variable

  on main.tf line 15:
  15: environment = "development"

Environment must be one of: dev, staging, prod.

Error: Invalid value for variable

  on main.tf line 18:
  18: public_subnet_cidr = "not-a-cidr"

The public_subnet_cidr must be a valid CIDR block.
```

### **🔧 Troubleshooting Steps:**
```bash
# 1. Check validation rules in variables.tf
grep -A 5 "validation" modules/vpc/variables.tf

# 2. Validate your values
terraform validate

# 3. Check allowed values in error message
# 4. Fix the values and re-run
```

### **✅ Fix:**
```hcl
environment         = "dev"           # Use allowed value
public_subnet_cidr  = "10.0.1.0/24"   # Valid CIDR
private_subnet_cidr = "10.0.2.0/24"   # Valid CIDR
```

---

## 🔥 Scenario 2: Module Source Path Issues

### **Break It:**
```hcl
# Wrong module source paths
module "vpc" {
  source = "./module/vpc"        # Missing 's' in modules
  # OR
  source = "../modules/vpc"      # Wrong relative path
  # OR
  source = "./modules/network"   # Module doesn't exist
}
```

### **Error Messages:**
```bash
Error: Module not found

  on main.tf line 12:
  12: module "vpc" {

The module directory "./module/vpc" does not exist.

Error: Failed to read module directory

Module directory "./modules/network" does not exist.
```

### **🔧 Troubleshooting Steps:**
```bash
# 1. Check if module directory exists
ls -la modules/
ls -la modules/vpc/

# 2. Verify file structure
tree .
# or
find . -name "*.tf" -type f

# 3. Check current working directory
pwd

# 4. Verify module source path syntax
```

### **✅ Fix:**
```bash
# Ensure correct directory structure
mkdir -p modules/vpc

# Use correct source path
source = "./modules/vpc"
```

---

## 🔥 Scenario 3: CIDR Overlap and Network Conflicts

### **Break It:**
```hcl
# Overlapping CIDR ranges
module "vpc" {
  source = "./modules/vpc"
  
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.1.0/25"  # Overlaps with public
  pod_cidr           = "10.0.1.0/16"   # Overlaps with both
}
```

### **Error Messages:**
```bash
Error: Error creating subnetwork: googleapi: Error 400: 
Invalid value for field 'resource.ipCidrRange': '10.0.1.0/25'. 
Subnetwork IP range overlaps with existing subnetwork in the same region.

Error: The specified CIDR block overlaps with existing subnets.
```

### **🔧 Troubleshooting Steps:**
```bash
# 1. List existing subnets
gcloud compute networks subnets list --network=your-vpc-name

# 2. Check CIDR calculations
# Use online CIDR calculator or command line
ipcalc 10.0.1.0/24
ipcalc 10.0.1.0/25

# 3. Plan the IP space properly
# Draw out your network design

# 4. Check for existing resources
terraform state list | grep subnet
```

### **✅ Fix:**
```hcl
# Non-overlapping CIDRs
public_subnet_cidr  = "10.0.1.0/24"    # 10.0.1.1 - 10.0.1.254
private_subnet_cidr = "10.0.2.0/24"    # 10.0.2.1 - 10.0.2.254
pod_cidr           = "10.1.0.0/16"     # 10.1.0.0 - 10.1.255.255
service_cidr       = "10.2.0.0/20"     # 10.2.0.0 - 10.2.15.255
```

---

## 🔥 Scenario 4: Provider Version Conflicts

### **Break It:**
```hcl
# In modules/vpc/versions.tf - Conflicting versions
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.0"  # Module requires 3.x
    }
  }
}

# In root providers.tf - Different version
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"  # Root requires 5.x
    }
  }
}
```

### **Error Messages:**
```bash
Error: Failed to query available provider packages

Could not retrieve the list of available versions for provider 
hashicorp/google: version constraints from child module are not 
satisfied by parent module.

Error: Inconsistent dependency lock file
```

### **🔧 Troubleshooting Steps:**
```bash
# 1. Check provider versions in all files
grep -r "version.*google" .

# 2. Check lock file
cat .terraform.lock.hcl

# 3. Remove lock file and re-init
rm .terraform.lock.hcl
rm -rf .terraform

# 4. Check provider compatibility
terraform providers
```

### **✅ Fix:**
```hcl
# Align versions - use compatible ranges
# In both module and root:
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0, < 6.0"  # Compatible range
    }
  }
}
```

---

## 🔥 Scenario 5: Resource Naming Conflicts

### **Break It:**
```hcl
# Deploying same module twice with same names
module "vpc_dev" {
  source   = "./modules/vpc"
  vpc_name = "my-vpc"
  # ... other config
}

module "vpc_staging" {
  source   = "./modules/vpc"
  vpc_name = "my-vpc"  # Same name - CONFLICT!
  # ... other config
}
```

### **Error Messages:**
```bash
Error: Error creating Network: googleapi: Error 409: 
The resource 'projects/project-id/global/networks/my-vpc' 
already exists, alreadyExists

Error: Resource already exists
```

### **🔧 Troubleshooting Steps:**
```bash
# 1. List existing resources
gcloud compute networks list
terraform state list

# 2. Check for name conflicts in plan
terraform plan | grep "will be created"

# 3. Review resource naming strategy
grep -r "google_compute_network" .

# 4. Check if resources exist outside Terraform
gcloud compute networks describe my-vpc
```

### **✅ Fix:**
```hcl
# Use unique naming per environment
module "vpc_dev" {
  source   = "./modules/vpc"
  vpc_name = "dev-my-vpc"
}

module "vpc_staging" {
  source   = "./modules/vpc"
  vpc_name = "staging-my-vpc"
}

# Or use locals for systematic naming
locals {
  vpc_name = "${var.environment}-${var.project_name}-vpc"
}
```

---

## 🔥 Scenario 6: State Backend Issues

### **Break It:**
```hcl
# Wrong backend configuration
terraform {
  backend "gcs" {
    bucket = "non-existent-bucket"
    prefix = "terraform/state/vpc"
  }
}

# Or missing permissions
# Or multiple people using same state file
```

### **Error Messages:**
```bash
Error: Failed to get existing workspaces: storage: bucket doesn't exist

Error: Error acquiring the state lock: ConditionalCheckFailedException

Error: Backend configuration changed
```

### **🔧 Troubleshooting Steps:**
```bash
# 1. Check if bucket exists
gsutil ls gs://terraform-statefile-bucket-tf2

# 2. Check permissions
gsutil iam get gs://terraform-statefile-bucket-tf2

# 3. Check for state locks
terraform force-unlock LOCK_ID

# 4. List state files
gsutil ls gs://terraform-statefile-bucket-tf2/terraform/state/

# 5. Check backend configuration
terraform init -backend-config=""
```

### **✅ Fix:**
```bash
# Create bucket if missing
gsutil mb gs://terraform-statefile-bucket-tf2

# Set proper permissions
gsutil iam ch user:your-email@domain.com:admin gs://terraform-statefile-bucket-tf2

# Re-initialize with correct backend
terraform init -reconfigure
```

---

## 🔥 Scenario 7: Missing Required APIs

### **Break It:**
```bash
# Deploy to project with disabled APIs
terraform apply
```

### **Error Messages:**
```bash
Error: Error creating Network: googleapi: Error 403: 
Compute Engine API has not been used in project PROJECT_ID 
before or it is disabled.

Error: API [compute.googleapis.com] not enabled on project [PROJECT_ID]
```

### **🔧 Troubleshooting Steps:**
```bash
# 1. Check enabled APIs
gcloud services list --enabled --project=PROJECT_ID

# 2. Check required APIs for resources
# Compute Engine API for VPC
# Container API for GKE

# 3. Enable required APIs
gcloud services enable compute.googleapis.com --project=PROJECT_ID
gcloud services enable container.googleapis.com --project=PROJECT_ID
```

### **✅ Fix:**
```bash
# Enable required APIs before terraform
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com

# Or add to terraform (but takes time)
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
  
  disable_dependent_services = true
}
```

---

## 🛠️ General Troubleshooting Workflow

### **Step 1: Read the Error Message**
```bash
# Always start with understanding the exact error
terraform apply 2>&1 | tee terraform-error.log
```

### **Step 2: Validate Configuration**
```bash
# Check syntax and basic validation
terraform validate
terraform fmt -check
```

### **Step 3: Plan First**
```bash
# Always plan before apply
terraform plan -out=tfplan
terraform show tfplan
```

### **Step 4: Debug with Verbose Output**
```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
terraform apply
```

### **Step 5: Check State**
```bash
# Examine current state
terraform state list
terraform state show resource.name
terraform refresh
```

### **Step 6: Resource-Specific Debugging**
```bash
# Check GCP resources directly
gcloud compute networks list
gcloud compute subnetworks list
gcloud projects get-iam-policy PROJECT_ID
```

## 🎯 Pro Tips for Prevention

1. **Always run `terraform plan` first**
2. **Use `terraform validate` in CI/CD**
3. **Implement pre-commit hooks**
4. **Use consistent naming conventions**
5. **Version your modules**
6. **Test modules in isolation**
7. **Document your troubleshooting steps**

## 🔧 Quick Debug Commands Cheat Sheet

```bash
# Validation
terraform validate
terraform fmt -check -diff

# Planning & State
terraform plan -refresh=false
terraform state list | grep vpc
terraform state show module.vpc.google_compute_network.vpc

# Provider & Version Issues
terraform providers
terraform version
terraform init -upgrade

# Force Actions (use carefully!)
terraform force-unlock LOCK_ID
terraform refresh
terraform apply -auto-approve -target=resource.name

# Clean Slate (nuclear option)
rm -rf .terraform .terraform.lock.hcl
terraform init
```

Practice these scenarios in a safe environment to become comfortable with troubleshooting Terraform modules!