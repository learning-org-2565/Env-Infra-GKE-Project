# backend.tf (Root)
terraform {
  backend "gcs" {
    bucket = "terraform-statefile-bucket-tf2"
    prefix = "terraform/state/vpc-module"
  }
}