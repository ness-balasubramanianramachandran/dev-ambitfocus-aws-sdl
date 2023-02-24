module "bsmi" {
  source = "../modules/terraform-aws-bsmi"
  providers = {
    vault.bsmi          = vault.bsmi,
    aws                 = aws,
    aws.cluster_creator = aws.cluster_creator
  }
  environment_code             = "de"
  customer_crmid               = "FIS 6015"
  infrastructure_dependencies  = local.infrastructure_dependencies
  infrastructure_instance_type = "small"

  timezone = local.timezone
  on_hours = local.on_hours
}
