data "aws_region" "current" {
}
data "aws_caller_identity" "current" {
}
data "aws_partition" "current" {
}
//Vault
//FIS certificate chain, used to create a Lambda layer so Lambda can validate SSL with FIS internal resources.
data "tls_certificate" "vault" {
  url = var.infrastructure_dependencies.vault.url
}
data "vault_generic_secret" "rds_sql_credentials" {
  provider = vault.bsmi
  path     = "bsmi-${var.environment_code}-kv/harness/sql-admin"
}
data "vault_generic_secret" "harness_delegate" {
  provider = vault.bsmi
  path     = "bsmi-${var.environment_code}-kv/harness_delegate"
}
data "vault_generic_secret" "fsx_ad_user" {
  provider = vault.bsmi
  path     = "bsmi-${var.environment_code}-kv/domain-admin"
}
data "vault_generic_secret" "end_user_domain_reader" {
  provider = vault.bsmi
  path     = "bsmi-${var.environment_code}-kv/end-user-domain-reader"
}

//BSMI network 
data "aws_subnets" "routable_front_end" {
  filter {
    name   = "vpc-id"
    values = [local.routable_vpc.id]
  }
  tags = {
    Name = var.infrastructure_dependencies.aws_account.network.snet_regex.routable_front_end
  }
}
data "aws_subnet" "routable_front_end" {
  for_each = toset(data.aws_subnets.routable_front_end.ids)
  id       = each.value
}

data "aws_subnets" "routable_app" {
  filter {
    name   = "vpc-id"
    values = [local.routable_vpc.id]
  }
  tags = {
    Name = var.infrastructure_dependencies.aws_account.network.snet_regex.routable_app
  }
}
data "aws_subnet" "routable_app" {
  for_each = toset(data.aws_subnets.routable_app.ids)
  id       = each.value
}
data "aws_subnets" "routable_rds" {
  filter {
    name   = "vpc-id"
    values = [local.routable_vpc.id]
  }
  tags = {
    Name = var.infrastructure_dependencies.aws_account.network.snet_regex.routable_rds
  }
}
data "aws_subnet" "routable_rds" {
  for_each = toset(data.aws_subnets.routable_rds.ids)
  id       = each.value
}
data "aws_subnets" "routable_connectivity" {
  filter {
    name   = "vpc-id"
    values = [local.routable_vpc.id]
  }
  tags = {
    Name = var.infrastructure_dependencies.aws_account.network.snet_regex.routable_connectivity
  }
}
data "aws_subnet" "routable_connectivity" {
  for_each = toset(data.aws_subnets.routable_connectivity.ids)
  id       = each.value
}

data "aws_subnets" "nr_compute" {
  filter {
    name   = "vpc-id"
    values = [local.nr_vpc.id]
  }
  tags = {
    Name = var.infrastructure_dependencies.aws_account.network.snet_regex.nr_compute
  }
}
data "aws_subnet" "nr_compute" {
  for_each = toset(data.aws_subnets.nr_compute.ids)
  id       = each.value
}
data "aws_subnets" "nr_connectivity" {
  filter {
    name   = "vpc-id"
    values = [local.nr_vpc.id]
  }
  tags = {
    Name = var.infrastructure_dependencies.aws_account.network.snet_regex.nr_connectivity
  }
}
data "aws_subnet" "nr_connectivity" {
  for_each = toset(data.aws_subnets.nr_connectivity.ids)
  id       = each.value
}

//Alarms
data "aws_sns_topic" "eks_alarms" {
  name = aws_sns_topic.eks_alarms.name
}
//Artifactory
data "artifactory_file" "eks_bootstrapper" {
  repository  = local.artifactory_bootstrapper_repo
  path        = local.artifactory_eks_bootstrapper_path
  output_path = "temp/EKSAuth.zip"
}
data "artifactory_file" "harness_bootstrapper" {
  repository  = local.artifactory_bootstrapper_repo
  path        = local.artifactory_harness_bootstrapper_path
  output_path = "temp/harness.zip"
}
data "archive_file" "fis_cacert" {
  type        = "zip"
  output_path = "${path.root}/temp/fis_cacert.zip"
  source {
    // take the first certificate in the chain as it is the root
    content  = data.tls_certificate.vault.certificates[0].cert_pem
    filename = "certs/fis_cacert.pem"
  }
}

//harness bootstrapper policies
data "aws_iam_policy_document" "harness_bootstrapper" {
  statement {
    sid = "LambdaManageNetworkInterfaces"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      variable = "ec2:SubnetID"
      values   = local.cluster_subnet_ids
      test     = "StringEqualsIfExists"
    }
    condition {
      variable = "ec2:Vpc"
      values   = [local.nr_vpc.arn]
      test     = "ArnEqualsIfExists"
    }
  }
  statement {
    sid = "LambdaLogging"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.harness_bootstrapper.arn}:log-stream:*"]
  }
  statement {
    sid = "EKS"
    actions = [
      "eks:DescribeCluster"
    ]
    effect    = "Allow"
    resources = [module.eks_cap_dev.cluster_arn]
  }
}

//harness delegate policies
data "aws_iam_policy_document" "harness_delegate" {
  statement {
    sid = "DescribeRegions"
    actions = [
      "ec2:DescribeRegions",
      "ec2:DescribeInstances",
      "rds:DescribeDBInstances"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  // used to validate external-dns functionality in Harness pipeline
  statement {
    sid = "ListServiceDiscoveryRoute53Records"
    actions = [
      "route53:ListResourceRecordSets"
    ]
    effect    = "Allow"
    resources = [aws_route53_zone.service_discovery.arn]
  }
}

//step-function-lambdas-policy
data "aws_iam_policy_document" "cpo_backend_lambda" {
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
      values   = local.cluster_subnet_ids
      test     = "StringEqualsIfExists"
    }
    condition {
      variable = "ec2:Vpc"
      values   = [local.nr_vpc.arn]
      test     = "ArnEqualsIfExists"
    }
  }
  statement {
    sid = "EKSDescribeCluster"
    actions = [
      "eks:DescribeCluster"
    ]
    effect    = "Allow"
    resources = [module.eks_cap_dev.cluster_arn]
  }
  statement {
    sid = "LambdaLogging"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = [for lg in aws_cloudwatch_log_group.cpo_backend_lambdas : "${lg.arn}:log-stream:*"]
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
    sid = "CreateAlarm"
    actions = [
      "cloudwatch:PutMetricAlarm"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/created-by"
      values   = ["compute-platform-orchestration"]
    }
  }
}

data "aws_iam_policy_document" "external_dns" {
  statement {
    sid = "ManageRecords"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]
    effect    = "Allow"
    resources = [aws_route53_zone.service_discovery.arn]
  }
  statement {
    sid = "ListHostedZones"
    actions = [
      "route53:ListHostedZones"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "kms_sns_eks_policy" {
  statement {
    sid    = "Enable IAM role permissions for local account only"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    resources = ["*"]
  }

  statement {
    sid    = "Allow service linked role use of the customer managed key"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
    }
    resources = ["*"]
  }

  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"
    actions = [
      "kms:CreateGrant"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
    }
    resources = ["*"]
    condition {
      test     = "Bool"
      values   = ["true"]
      variable = "kms:GrantIsForAWSResource"
    }
  }
}


// KMS encryption key for sqs dlq for lambda orchestration layer
data "aws_iam_policy_document" "sqs_dlq" {
  statement {
    sid = "Enable IAM role permissions for local account only"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    resources = [ "*" ]
  }


  statement {
    sid = "Allow direct access to key metadata to the account"
    effect = "Allow"
    actions = [
      "kms:Describe*",
      "kms:Get*",
      "kms:List*",
      "kms:RevokeGrant"
    ]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    resources = ["*"]
  }


  statement {
    sid = "Allow access through Simple Queue Service and AWS Lambda"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    principals {
      type = "Service"
      identifiers = ["sqs.amazonaws.com", "lambda.amazonaws.com"]
    }
    resources = ["*"]
  }


}



data "aws_iam_policy_document" "cpo_sqs_kms" {
  statement {
    sid    = "LambdaDLQSendMessage"
    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "LambdaDLQKMSOperation"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = ["*"]
  }
}