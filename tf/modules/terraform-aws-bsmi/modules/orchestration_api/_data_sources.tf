data "aws_region" "current" {
}
data "aws_caller_identity" "current" {
}
data "aws_partition" "current" {
}

//cpo-api-lambda-policy
data "aws_iam_policy_document" "cpo_api_lambda" {
  statement {
    sid = "LambdaManageVPCNetworkInterfaces"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      variable = "ec2:SubnetID"
      values   = var.subnet_ids
      test     = "StringEqualsIfExists"
    }
    condition {
      variable = "ec2:Vpc"
      values   = [var.nr_vpc.arn]
      test     = "ArnEqualsIfExists"
    }
  }
  statement {
    sid = "EKSDescribeCluster"
    actions = [
      "eks:DescribeCluster"
    ]
    effect    = "Allow"
    resources = [var.eks_cluster_arn]
  }
  statement {
    sid = "LambdaLogging"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = [for lg in aws_cloudwatch_log_group.apigw_lambdas : "${lg.arn}:log-stream:*"]
  }
  statement {
    // DescribeAlarms must allow * WITHOUT conditions or else it will return 403 if alarm doesnt exist
    sid = "DescribeAlarms"
    actions = [
      "cloudwatch:DescribeAlarms"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "DeleteAlarms"
    actions = [
      "cloudwatch:DeleteAlarms"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/created-by"
      values   = ["compute-platform-orchestration"]
    }
  }
  statement {
    sid = "StepFunctionStartExecution"
    actions = [
      "states:StartExecution"
    ]
    effect = "Allow"
    resources = [
      var.step_function_arn
    ]
  }
  statement {
    sid = "StepFunctionManageExecution"
    actions = [
      "states:StopExecution",
      "states:DescribeExecution"
    ]
    effect = "Allow"
    resources = [
      "arn:${data.aws_partition.current.id}:states:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:execution:${var.step_function_name}:*"
    ]
  }
}
