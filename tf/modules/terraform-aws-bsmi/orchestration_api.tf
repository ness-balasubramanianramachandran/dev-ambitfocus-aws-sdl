// This role is created outside the orchestration api module to
// avoid a circular dependency between the eks module & orchestration api module
resource "aws_iam_role" "orchestration_lambda" {
  name = "${local.name_prefix}cpo-api-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })

  tags = merge(local.default_tags,
    {
      Name = "${local.name_prefix}cpo-api-lambda"
  })
}

module "orchestration_api" {
  source = "./modules/orchestration_api"

  name_prefix = local.name_prefix

  # passing cluster variables here, since the orchestration api and EKS cluster will be deployed in the same VPC.
  nr_vpc     = local.nr_vpc
  subnet_ids = local.cluster_subnet_ids

  # should be accessible from the routable vpc so BSMI can call the api.
  vpc_access = local.routable_vpc

  orchestration_lambda_role_name = aws_iam_role.orchestration_lambda.name
  step_function_name             = aws_sfn_state_machine.cpo_backend_step_function.name
  step_function_arn              = aws_sfn_state_machine.cpo_backend_step_function.arn
  eks_cluster_name               = module.eks_cap_dev.cluster_name
  eks_cluster_arn                = module.eks_cap_dev.cluster_arn

  fis_tags = {
    AppGroupEmail   = local.default_tags.AppGroupEmail
    BUC             = local.default_tags.BUC
    CustomerCRMID   = local.default_tags.CustomerCRMID
    EnvironmentType = local.default_tags.EnvironmentType
    SupportGroup    = local.default_tags.SupportGroup
  }
}
