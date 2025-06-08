#!/bin/bash

# Terraform Module Failure Testing Script
# This script will systematically test various failure scenarios

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Backup original files
backup_files() {
    echo -e "${BLUE}📁 Creating backup of original files...${NC}"
    cp main.tf main.tf.backup
    cp terraform.tfvars terraform.tfvars.backup 2>/dev/null || echo "No terraform.tfvars found"
    cp modules/vpc/versions.tf modules/vpc/versions.tf.backup
    cp backend.tf backend.tf.backup
    echo -e "${GREEN}✅ Backup created${NC}"
}

# Restore original files
restore_files() {
    echo -e "${BLUE}🔄 Restoring original files...${NC}"
    cp main.tf.backup main.tf
    cp terraform.tfvars.backup terraform.tfvars 2>/dev/null || echo "No terraform.tfvars backup found"
    cp modules/vpc/versions.tf.backup modules/vpc/versions.tf
    cp backend.tf.backup backend.tf
    echo -e "${GREEN}✅ Files restored${NC}"
}

# Test runner function
run_test() {
    local test_name="$1"
    local description="$2"
    
    echo -e "\n${YELLOW}🧪 Testing: $test_name${NC}"
    echo -e "${BLUE}Description: $description${NC}"
    echo -e "${RED}Expected: This should FAIL${NC}"
    
    read -p "Press Enter to run test, 's' to skip: " choice
    if [[ $choice == "s" ]]; then
        echo -e "${YELLOW}⏭️  Skipped${NC}"
        return
    fi
    
    echo -e "${BLUE}Running: terraform validate${NC}"
    if terraform validate 2>&1; then
        echo -e "${YELLOW}⚠️  Validation passed, trying plan...${NC}"
        if terraform plan -input=false 2>&1; then
            echo -e "${YELLOW}⚠️  Plan succeeded, this test didn't break as expected${NC}"
        else
            echo -e "${GREEN}✅ Plan failed as expected${NC}"
        fi
    else
        echo -e "${GREEN}✅ Validation failed as expected${NC}"
    fi
    
    echo -e "${BLUE}Press Enter to continue to next test...${NC}"
    read
}

# Test scenarios
test_invalid_environment() {
    cat > terraform.tfvars << EOF
project_id  = "your-project-id"
region      = "us-central1"
zone        = "us-central1-a"
environment = "development"
EOF
    
    run_test "Invalid Environment Value" "Using 'development' instead of allowed values (dev, staging, prod)"
}

test_invalid_cidr() {
    # Restore tfvars first
    cp terraform.tfvars.backup terraform.tfvars 2>/dev/null || true
    
    # Edit main.tf to have invalid CIDR
    sed -i.tmp 's/public_subnet_cidr    = "10.0.1.0\/24"/public_subnet_cidr    = "not-a-valid-cidr"/' main.tf
    
    run_test "Invalid CIDR Format" "Using invalid CIDR format 'not-a-valid-cidr'"
    
    # Restore main.tf
    cp main.tf.backup main.tf
}

test_overlapping_cidrs() {
    # Edit main.tf for overlapping CIDRs
    sed -i.tmp 's/private_subnet_cidr   = "10.0.2.0\/24"/private_subnet_cidr   = "10.0.1.128\/25"/' main.tf
    
    run_test "Overlapping CIDR Ranges" "Private subnet CIDR overlaps with public subnet"
    
    # Restore main.tf
    cp main.tf.backup main.tf
}

test_wrong_module_path() {
    # Edit main.tf to have wrong module path
    sed -i.tmp 's/source = ".\/modules\/vpc"/source = ".\/module\/vpc"/' main.tf
    
    run_test "Wrong Module Source Path" "Missing 's' in modules directory name"
    
    # Restore main.tf
    cp main.tf.backup main.tf
}

test_version_conflict() {
    # Edit module versions.tf to conflict with root
    cat > modules/vpc/versions.tf << EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.0"
    }
  }
}
EOF
    
    # Remove lock file to force version check
    rm -f .terraform.lock.hcl
    
    run_test "Provider Version Conflict" "Module requires google provider ~> 3.0 while root uses ~> 4.0"
    
    # Restore versions.tf
    cp modules/vpc/versions.tf.backup modules/vpc/versions.tf
}

test_missing_variable() {
    # Edit main.tf to comment out required variable
    sed -i.tmp 's/project_id            = var.project_id/# project_id            = var.project_id/' main.tf
    
    run_test "Missing Required Variable" "Commenting out required project_id variable"
    
    # Restore main.tf
    cp main.tf.backup main.tf
}

test_wrong_backend() {
    # Edit backend.tf to use non-existent bucket
    sed -i.tmp 's/bucket = "terraform-statefile-bucket-tf2"/bucket = "this-bucket-does-not-exist-123456"/' backend.tf
    
    # Need to re-init to test backend
    rm -rf .terraform
    
    run_test "Wrong Backend Configuration" "Using non-existent GCS bucket"
    
    # Restore backend.tf and re-init
    cp backend.tf.backup backend.tf
    terraform init -input=false
}

test_type_mismatch() {
    # Edit main.tf to have wrong types
    sed -i.tmp 's/vpc_name              = local.vpc_name/vpc_name              = 12345/' main.tf
    sed -i.tmp 's/enable_nat_gateway    = true/enable_nat_gateway    = "yes"/' main.tf
    
    run_test "Type Mismatch Error" "Using number for string variable and string for boolean"
    
    # Restore main.tf
    cp main.tf.backup main.tf
}

# Main execution
main() {
    echo -e "${GREEN}🚀 Terraform Module Failure Testing Script${NC}"
    echo -e "${BLUE}This script will test various failure scenarios with your VPC module${NC}"
    echo -e "${YELLOW}⚠️  Make sure you're in the root directory with your Terraform files${NC}"
    echo ""
    
    # Check if required files exist
    if [[ ! -f "main.tf" || ! -f "modules/vpc/main.tf" ]]; then
        echo -e "${RED}❌ Required files not found. Make sure you're in the correct directory.${NC}"
        exit 1
    fi
    
    read -p "Do you want to proceed with testing? (y/N): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        exit 0
    fi
    
    # Create backups
    backup_files
    
    # Trap to restore files on exit
    trap restore_files EXIT
    
    # Run tests
    echo -e "\n${GREEN}Starting failure scenario tests...${NC}"
    
    test_invalid_environment
    test_invalid_cidr
    test_overlapping_cidrs
    test_wrong_module_path
    test_version_conflict
    test_missing_variable
    test_wrong_backend
    test_type_mismatch
    
    echo -e "\n${GREEN}🎉 All tests completed!${NC}"
    echo -e "${BLUE}You've now seen common Terraform failure scenarios and how to troubleshoot them.${NC}"
    echo -e "${YELLOW}Remember: Always read error messages carefully and use 'terraform validate' and 'terraform plan' before applying.${NC}"
}

# Cleanup function for manual interrupt
cleanup() {
    echo -e "\n${YELLOW}⚠️  Script interrupted. Restoring files...${NC}"
    restore_files
    exit 130
}

trap cleanup INT

# Run main function
main "$@"