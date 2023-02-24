output "eks_api_sg_id" {
  description = "The ID of the security group that protects EKS API endpoints"
  value       = module.eks_cap_dev.cluster_kubernetes_api_security_group_id
}
output "app_server_sg_id" {
  description = "Application Server(s) Security Group"
  value       = aws_security_group.application_server.id
}
output "sql_server_sg_id" {
  description = "SQL Server(s) Security Group"
  value       = aws_security_group.mssql_server.id
}
output "orchestration_api_private_url" {
  description = "The domain to use to access the compute platform orchestration api from the BSMI VPC"
  value       = module.orchestration_api.api_gateway_private_url
}
output "snets" {
  description = "CIDR blocks and IDs for each subnet type: routable_front_end, routable_app, routable_rds etc."
  value       = local.snets
}
output "environment_code" {
  description = "Two letter environment code"
  value       = var.environment_code
}
output "default_tags" {
  description = "FIS default tags"
  value       = local.default_tags
}
output "ec2_tags" {
  description = "FIS ec2 tags"
  value       = local.ec2_tags
}
