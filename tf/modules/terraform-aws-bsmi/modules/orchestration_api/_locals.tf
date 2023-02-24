locals {
  fis_tags = var.fis_tags

  apigw_methods = tomap({
    "start" = {
      resource             = aws_api_gateway_resource.compute_platform
      http_method          = "POST"
      lambda_function_name = "${var.name_prefix}cpo-api-start"
    }
    "status" = {
      resource             = aws_api_gateway_resource.compute_platform_detail
      http_method          = "GET"
      lambda_function_name = "${var.name_prefix}cpo-api-status"
    }
    "destroy" = {
      resource             = aws_api_gateway_resource.compute_platform_detail
      http_method          = "DELETE"
      lambda_function_name = "${var.name_prefix}cpo-api-destroy"
    }
  })

  log_retention_days = 30

  apigw_lambdas = toset([
    for k, v in local.apigw_methods :
    {
      name = v.lambda_function_name
      // arn:{partition}:lambda:{region}:{account}:function:{function_name}
      arn = "arn:${data.aws_partition.current.id}:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${v.lambda_function_name}"
    }
  ])

  lambda_env_vars = {
    STATE_MACHINE_ARN = var.step_function_arn
    EKS_CLUSTER_NAME  = var.eks_cluster_name
  }
}