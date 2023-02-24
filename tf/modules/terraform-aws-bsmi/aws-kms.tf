// KMS key for EBS volume encryption of EKS nodes
resource "aws_kms_key" "eks_ebs" {
  description              = "KMS key for EBS volume encryption of EKS nodes"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  deletion_window_in_days  = 7
  policy                   = <<JSON
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
      {
          "Sid": "Enable IAM User Permissions",
          "Effect": "Allow",
          "Principal": {
              "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          },
          "Action": "kms:*",
          "Resource": "*"
      },
      {
        "Sid": "Allow service-linked role use of the customer managed key",
        "Effect": "Allow",
        "Principal": {
            "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action": [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
        ],
        "Resource": "*"
      },
      {
        "Sid": "Allow attachment of persistent resources",
        "Effect": "Allow",
        "Principal": {
            "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action": [
            "kms:CreateGrant"
        ],
        "Resource": "*",
        "Condition": {
            "Bool": {
                "kms:GrantIsForAWSResource": true
            }
          }
      }
  ]
}
JSON
  tags                     = merge(local.default_tags, { "Name" = "${local.cluster_name}-block-device-encryption" })
}
//create KMS key for the RDS SQL encryption
resource "aws_kms_key" "rds_sql" {
  description              = "KMS CMK for RDS SQL encryption"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  deletion_window_in_days  = 7
  policy                   = <<JSON
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
      {
          "Sid": "Enable IAM User Permissions",
          "Effect": "Allow",
          "Principal": {
              "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          },
          "Action": "kms:*",
          "Resource": "*"
      },
      {
        "Sid": "Allow service-linked role use of the customer managed key",
        "Effect": "Allow",
        "Principal": {
            "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action": [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
        ],
        "Resource": "*"
      },
      {
        "Sid": "Allow attachment of persistent resources",
        "Effect": "Allow",
        "Principal": {
            "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action": [
            "kms:CreateGrant"
        ],
        "Resource": "*",
        "Condition": {
            "Bool": {
                "kms:GrantIsForAWSResource": true
            }
          }
      }
  ]
}
JSON
  tags                     = merge(local.default_tags, { "Name" = "${local.name_prefix}rds-sql" })
}

# create KMS key for the SNS EKS notifications
resource "aws_kms_key" "sns_eks_cmk" {
  description              = "KMS CMK to encrypt SNS notifications at rest for EKS alarms"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  deletion_window_in_days  = 7
  policy                   = data.aws_iam_policy_document.kms_sns_eks_policy.json
  tags                     = merge(local.default_tags, { "Name" = "${local.name_prefix}sns-eks-cmk" })

}

# create KMS CMK for sqs dlq for aws lambda orchestration layer
resource "aws_kms_key" "sqs_dlq" {
  description = "KMS CMK to encrypt SQS DLQ at rest"
  key_usage = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation = true
  deletion_window_in_days = 7
  policy = data.aws_iam_policy_document.sqs_dlq.json
  tags = merge(local.default_tags, { "Name" = "${local.name_prefix}kms-sqs-dlq" })
}

# Alias for eks ebs 
resource "aws_kms_alias" "eks_ebs" {
  name          = "alias/${local.name_prefix}block-device-encryption"
  target_key_id = aws_kms_key.eks_ebs.key_id
}


# Alias for rds sql database 
resource "aws_kms_alias" "rds_sql" {
  name          = "alias/${local.name_prefix}rds-sql"
  target_key_id = aws_kms_key.rds_sql.key_id
}

# Alias for sns eks notification key 
resource "aws_kms_alias" "sns_eks_cmk_alias" {
  name          = "alias/${local.name_prefix}sns-eks"
  target_key_id = aws_kms_key.sns_eks_cmk.key_id
}

# Alias for kms sqs dlq key
resource "aws_kms_alias" "sqs_dlq" {
  name = "alias/${local.name_prefix}sqs-dlq"
  target_key_id = aws_kms_key.sqs_dlq.key_id
}