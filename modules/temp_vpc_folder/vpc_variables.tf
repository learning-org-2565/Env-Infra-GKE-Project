# =============================================================================
# modules/vpc/variables.tf
# =============================================================================
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR range for the public subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "The public_subnet_cidr must be a valid CIDR block."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR range for the private subnet"
  type        = string
  default     = "10.0.2.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "The private_subnet_cidr must be a valid CIDR block."
  }
}

variable "pod_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.pod_cidr, 0))
    error_message = "The pod_cidr must be a valid CIDR block."
  }
}

variable "service_cidr" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.2.0.0/20"

  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "The service_cidr must be a valid CIDR block."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnet"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}