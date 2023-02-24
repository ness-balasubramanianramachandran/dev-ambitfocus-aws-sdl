//Create IAM role for the bootstrapper lambda
resource "aws_iam_role" "harness_bootstrapper" {
  name = "${local.cluster_name}-harness-bootstrapper"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}harness-bootstrapper"
  })
}

// harness_bootstrapper policy
resource "aws_iam_policy" "harness_bootstrapper" {
  name   = "${local.cluster_name}-harness-bootstrapper"
  policy = data.aws_iam_policy_document.harness_bootstrapper.json

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}harness-bootstrapper"
  })
}

// harness delegate policy (allowing the harness delegate to do things on AWS services: e.g. deploy lambda...)
//Policy attached by EKS module to the relevant IAM role used for Harness Delegate SA (IRSA)
resource "aws_iam_policy" "harness_delegate" {
  name   = "${local.cluster_name}-harness-delegate"
  policy = data.aws_iam_policy_document.harness_delegate.json

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}harness-delegate"
  })
}

// the policy attachment
resource "aws_iam_role_policy_attachment" "harness_bootstrapper" {
  role       = aws_iam_role.harness_bootstrapper.name
  policy_arn = aws_iam_policy.harness_bootstrapper.arn
}

//CloudWatch log group
resource "aws_cloudwatch_log_group" "harness_bootstrapper" {
  name              = "/aws/lambda/${local.cluster_name}-harness-bootstrapper"
  retention_in_days = local.cluster_log_retention_days

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}harness-bootstrapper"
  })

}

//Create the bootstrapper lambda that will deploy Harness Delegate in EKS cluster
resource "aws_lambda_function" "harness_bootstrapper" {
  description      = "Deploys k8s Harness Delegate in EKS cluster"
  filename         = data.artifactory_file.harness_bootstrapper.output_path
  function_name    = "${local.cluster_name}-harness-bootstrapper"
  role             = aws_iam_role.harness_bootstrapper.arn
  handler          = "FIS.Bancware.Cloud.Aws.Harness::FIS.Bancware.Cloud.Aws.Harness.HarnessDeployer::Deploy"
  source_code_hash = filebase64sha256(data.artifactory_file.harness_bootstrapper.output_path)

  runtime                        = "dotnet6"
  timeout                        = 30
  memory_size                    = 128
  reserved_concurrent_executions = 20

  vpc_config {
    subnet_ids         = local.cluster_subnet_ids
    security_group_ids = [module.eks_cap_dev.aws_auth_lambda_security_group_id]
  }

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}harness-bootstrapper"
  })

  depends_on = [
    aws_iam_role_policy_attachment.harness_bootstrapper,
    aws_cloudwatch_log_group.harness_bootstrapper
  ]

}

//invoke the lambda function
resource "aws_lambda_invocation" "harness_bootstrapper" {
  function_name = aws_lambda_function.harness_bootstrapper.function_name

  triggers = {
    file_hash = aws_lambda_function.harness_bootstrapper.source_code_hash
  }

  input = jsonencode(
    {
      "ClusterName"   = module.eks_cap_dev.cluster_name,
      "Namespace"     = "harness-delegate",
      "DelegateName"  = local.harness_delegate_name,
      "DelegateToken" = local.harness_delegate_token,
      "AccountId"     = local.harness_account_id,
      "DelegateContainer" = {
        "Image" = "harness/delegate:latest"
      },
      "ServiceAccountRoleArn" = module.eks_cap_dev.iam_roles_for_service_accounts["harness_delegate"].iam_role_arn
      "EnvironmentVariables" = {
        "DELEGATE_PROFILE" = local.harness_delegate_profile
      }
    }
  )
}
