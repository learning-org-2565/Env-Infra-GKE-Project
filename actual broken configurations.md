# ===============================================================================
# TEST 1: Variable Validation Failures
# ===============================================================================
# Replace your terraform.tfvars with this:

project_id  = "your-project-id"
region      = "us-central1"
zone        = "us-central1-a"
environment = "development"    # ❌ BREAK: Invalid environment value

# Expected Error:
# Error: Invalid value for variable
# Environment must be one of: dev, staging, prod.

# ===============================================================================
# TEST 2: Invalid CIDR Ranges
# ===============================================================================
# Replace the module block in your main.tf:

module "vpc" {
  source = "./modules/vpc"

  project_id            = var.project_id
  region                = var.region
  vpc_name              = local.vpc_name
  public_subnet_cidr    = "not-a-valid-cidr"     # ❌ BREAK: Invalid CIDR
  private_subnet_cidr   = "300.0.2.0/24"         # ❌ BREAK: Invalid IP range
  pod_cidr              = "10.1.0.0/16"
  service_cidr          = "10.2.0.0/20"
  enable_nat_gateway    = true
  enable_flow_logs      = false
  labels                = local.common_labels
}

# Expected Error:
# Error: Invalid value for variable
# The public_subnet_cidr must be a valid CIDR block.

# ===============================================================================
# TEST 3: Overlapping CIDR Ranges
# ===============================================================================
# Replace with overlapping CIDRs:

module "vpc" {
  source = "./modules/vpc"

  project_id            = var.project_id
  region                = var.region
  vpc_name              = local.vpc_name
  public_subnet_cidr    = "10.0.1.0/24"          # 10.0.1.0 - 10.0.1.255
  private_subnet_cidr   = "10.0.1.128/25"        # ❌ BREAK: Overlaps with public
  pod_cidr              = "10.0.0.0/16"          # ❌ BREAK: Overlaps with both
  service_cidr          = "10.2.0.0/20"
  enable_nat_gateway    = true
  enable_flow_logs      = false
  labels                = local.common_labels
}

# Expected Error:
# Error: Error creating subnetwork: googleapi: Error 400
# Subnetwork IP range overlaps with existing subnetwork

# ===============================================================================
# TEST 4: Wrong Module Source Path
# ===============================================================================
# Change the source path:

module "vpc" {
  source = "./module/vpc"        # ❌ BREAK: Missing 's' in modules
  # ... rest of config
}

# Or try:
module "vpc" {
  source = "./modules/network"   # ❌ BREAK: Directory doesn't exist
  # ... rest of config
}

# Expected Error:
# Error: Module not found
# The module directory "./module/vpc" does not exist.

# ===============================================================================
# TEST 5: Provider Version Conflicts
# ===============================================================================
# Edit your modules/vpc/versions.tf to have conflicting version:

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.0"              # ❌ BREAK: Conflicts with root version
    }
  }
}

# While keeping root providers.tf as:
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"              # Different major version
    }
  }
}

# Expected Error:
# Error: Failed to query available provider packages
# version constraints from child module are not satisfied

# ===============================================================================
# TEST 6: Duplicate Resource Names
# ===============================================================================
# Add two modules with same vpc_name in main.tf:

module "vpc_first" {
  source = "./modules/vpc"

  project_id            = var.project_id
  region                = var.region
  vpc_name              = "test-vpc"              # Same name
  public_subnet_cidr    = "10.0.1.0/24"
  private_subnet_cidr   = "10.0.2.0/24"
  pod_cidr              = "10.1.0.0/16"
  service_cidr          = "10.2.0.0/20"
  enable_nat_gateway    = true
  labels                = local.common_labels
}

module "vpc_second" {
  source = "./modules/vpc"

  project_id            = var.project_id
  region                = var.region
  vpc_name              = "test-vpc"              # ❌ BREAK: Same name!
  public_subnet_cidr    = "10.3.1.0/24"
  private_subnet_cidr   = "10.3.2.0/24"
  pod_cidr              = "10.4.0.0/16"
  service_cidr          = "10.5.0.0/20"
  enable_nat_gateway    = true
  labels                = local.common_labels
}

# Expected Error:
# Error: Error creating Network: googleapi: Error 409
# The resource already exists

# ===============================================================================
# TEST 7: Missing Required Variable
# ===============================================================================
# Remove a required variable from module call:

module "vpc" {
  source = "./modules/vpc"

  # project_id            = var.project_id     # ❌ BREAK: Comment out required var
  region                = var.region
  vpc_name              = local.vpc_name
  public_subnet_cidr    = "10.0.1.0/24"
  private_subnet_cidr   = "10.0.2.0/24"
  labels                = local.common_labels
}

# Expected Error:
# Error: Missing required argument
# The argument "project_id" is required, but no definition was found.

# ===============================================================================
# TEST 8: Wrong Backend Configuration
# ===============================================================================
# Edit your backend.tf:

terraform {
  backend "gcs" {
    bucket = "this-bucket-does-not-exist-123456789"  # ❌ BREAK: Non-existent bucket
    prefix = "terraform/state/vpc-module"
  }
}

# Expected Error:
# Error: Failed to get existing workspaces: storage: bucket doesn't exist

# ===============================================================================
# TEST 9: Type Mismatch Error
# ===============================================================================
# Pass wrong type to module:

module "vpc" {
  source = "./modules/vpc"

  project_id            = var.project_id
  region                = var.region
  vpc_name              = 12345                     # ❌ BREAK: Number instead of string
  public_subnet_cidr    = "10.0.1.0/24"
  private_subnet_cidr   = "10.0.2.0/24"
  enable_nat_gateway    = "yes"                     # ❌ BREAK: String instead of bool
  labels                = "invalid"                 # ❌ BREAK: String instead of map
}

# Expected Error:
# Error: Invalid value for input variable
# The given value is not suitable for declared variable type

# ===============================================================================
# TEST 10: Circular Dependency
# ===============================================================================
# Create circular reference in outputs/variables:

# In modules/vpc/main.tf, add this resource that depends on an output:
resource "google_compute_address" "static_ip" {
  name   = "${var.vpc_name}-static-ip"
  region = var.region
  
  # This creates circular dependency if static_ip is used in network creation
  depends_on = [google_compute_network.vpc]
}

# And then try to use this in network resource somehow (contrived but shows concept)

# Expected Error:
# Error: Cycle: module.vpc.google_compute_address.static_ip, 
# module.vpc.google_compute_network.vpc

# ===============================================================================
# TESTING COMMANDS TO RUN EACH SCENARIO
# ===============================================================================

# For each test above:
# 1. Make the change
# 2. Run these commands:

terraform validate           # See validation errors
terraform plan              # See planning errors  
terraform apply             # See apply errors

# Debug commands:
export TF_LOG=DEBUG
terraform plan 2>&1 | tee debug.log

# Reset to working state:
git checkout -- .           # If using git
# Or manually restore working files

# ===============================================================================
# ADVANCED BREAKING SCENARIOS
# ===============================================================================

# TEST 11: Resource Dependencies Break
# Delete a resource that others depend on:
# Comment out the VPC resource in modules/vpc/main.tf:

# resource "google_compute_network" "vpc" {
#   name                    = var.vpc_name
#   auto_create_subnetworks = false
#   description             = "VPC managed by Terraform"
#   routing_mode            = "REGIONAL"
# }

# Keep subnet resources that depend on it
# Expected: Dependency errors

# TEST 12: State Corruption Simulation
# Manually edit terraform.tfstate (make backup first!):
# Change a resource ID to something invalid

# TEST 13: API Permissions Issue
# Remove Compute Engine API permissions from service account
# Expected: 403 permission errors

# TEST 14: Resource Quotas Exceeded  
# Try to create resources that exceed project quotas
# (Create many large instances, networks, etc.)

# TEST 15: Terraform Version Mismatch
# Use very old terraform version with modern providers
# Use terraform 0.12 syntax with terraform 1.x