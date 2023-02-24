/**
 * File provided as part of base bitbucket scaffolding
 * this file should contain output variables.
 */
output "orchestration_api_private_url" {
  description = "The domain to use to access the compute platform orchestration api from the BSMI VPC"
  value       = module.bsmi.orchestration_api_private_url
}
