# =============================================================================
# outputs.tf (Root) - Updated with CloudSQL Outputs
# =============================================================================

output "vpc_details" {
  description = "VPC module outputs"
  value = {
    vpc_id            = module.vpc.vpc_id
    vpc_name          = module.vpc.vpc_name
    public_subnet_id  = module.vpc.public_subnet_id
    private_subnet_id = module.vpc.private_subnet_id
    pod_cidr          = module.vpc.pod_cidr
    service_cidr      = module.vpc.service_cidr
  }
}

output "gke_details" {
  description = "GKE module outputs"
  value = {
    cluster_name     = module.gke.cluster_name
    cluster_location = module.gke.cluster_location
    service_account  = module.gke.service_account_email
    kubectl_command  = module.gke.kubectl_command
    cluster_zones    = module.gke.cluster_zones
  }
}

output "kubectl_command" {
  description = "Command to configure kubectl"
  value       = module.gke.kubectl_command
}

# CloudSQL outputs (only available in dev environment)
output "cloudsql_details" {
  description = "CloudSQL module outputs (dev environment only)"
  value = local.deploy_cloudsql ? {
    instance_name   = module.cloudsql[0].database_connection_info.instance_name
    database_name   = module.cloudsql[0].database_connection_info.database_name
    private_ip      = module.cloudsql[0].database_connection_info.private_ip
    connection_name = module.cloudsql[0].connection_name
  } : null
}

output "cloudsql_connection_info" {
  description = "CloudSQL connection information for applications (dev only)"
  value = local.deploy_cloudsql ? {
    host     = module.cloudsql[0].cloudsql_private_ip
    port     = "5432"
    database = module.cloudsql[0].database_connection_info.database_name
    username = var.sql_app_user
  } : null
}

# Sensitive outputs
output "cloudsql_app_password" {
  description = "CloudSQL application password (dev only)"
  value       = local.deploy_cloudsql ? module.cloudsql[0].app_user_password : null
  sensitive   = true
}

output "cloudsql_connection_string" {
  description = "CloudSQL connection string (dev only)"
  value       = local.deploy_cloudsql ? module.cloudsql[0].database_connection_string : null
  sensitive   = true
}