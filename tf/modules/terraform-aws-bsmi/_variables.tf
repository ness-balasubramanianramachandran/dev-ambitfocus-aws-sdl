variable "environment_code" {
  description = "Unique two letter environment code. Used in name prefix of all resources that belong to this infrastructure instance."
  type        = string
}
variable "customer_crmid" {
  description = "Customer CRM ID (tenant ID)"
  type        = string
}
variable "infrastructure_dependencies" {
  description = "Integration with FIS environment (Vault, AD, Artifactory, DNS...) and pre-provisioned elements in AWS account (network, IAM roles etc.)"
}
variable "infrastructure_instance_type" {
  description = "Type (size) of the infrastructure instance: small, medium or large"
}
variable "timezone" {
  description = "Timezone of the AWS region where the infrastructure is provisioned (needed for the RDS SQL database)"
  type        = string
}
variable "on_hours" {
  description = "On Hours. To be used in Dev environments..."
  type        = string
  default     = "Always"
}
