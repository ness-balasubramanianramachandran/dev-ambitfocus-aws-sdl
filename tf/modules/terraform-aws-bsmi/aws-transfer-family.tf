//Bucket Creation for SFTP Transfer Family

resource "aws_s3_bucket" "sftp" {
  bucket = "${local.name_prefix}sftp-transferfamily"
  tags   = merge(local.default_tags, local.s3_tags, { "Name" = "${local.name_prefix}sftp-transferfamily" })

}
resource "aws_s3_bucket_acl" "sftp" {
  bucket = aws_s3_bucket.sftp.id
  acl    = "private"
}

resource "aws_s3_object" "sftp" {
  bucket = aws_s3_bucket.sftp.id
  acl    = "private"
  key    = "client-files-app"
  server_side_encryption = "AES256" 
  tags = merge(local.default_tags, { "Name" = "${local.name_prefix}client-files-app" })  
}

//Security Group Creation for SFTP Transfer Family

resource "aws_security_group" "sftp" {
  name        = "${local.name_prefix}sftp-trsfmly"
  description = "Security group for the SFTP transfer family"
  vpc_id      = local.routable_vpc.id

  tags = merge(local.default_tags, { "Name" = "${local.name_prefix}sftp-trsfmly" })
}
// create sg rules
resource "aws_security_group_rule" "SSH_to_transfer" { 
  description              = "Allow connections to tranfer family ssh port"  
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = local.snets.routable_front_end.cidrs
  security_group_id        = aws_security_group.sftp.id
}
resource "aws_security_group_rule" "sftp_from_fis" {
  description       = "Allow inbound connections from FIS domain cotroller(s)"
  type              = "ingress"
  from_port         = 49152
  to_port           = 65535
  protocol          = "TCP"
  security_group_id = aws_security_group.sftp.id
  cidr_blocks       = local.ad_cidrs
}
resource "aws_security_group_rule" "tsfmly_from_fis" {
  description       = "Allow inbound connections (UDP) from FIS domain cotroller(s)"
  type              = "ingress"
  from_port         = 49152
  to_port           = 65535
  protocol          = "UDP"
  security_group_id = aws_security_group.sftp.id
  cidr_blocks       = local.ad_cidrs
}

// Creating AD connector
resource "aws_directory_service_directory" "this" {
  name     = var.infrastructure_dependencies.dns.domains.fnfis-com
  password = data.vault_generic_secret.end_user_domain_reader.data["password"]
  size     = "Small"
  type     = "ADConnector"

  connect_settings {
    customer_dns_ips  = var.infrastructure_dependencies.dns.domain_controller_ips
    customer_username =  data.vault_generic_secret.end_user_domain_reader.data["username"]
    subnet_ids        = local.snets.routable_app.ids
    vpc_id            = local.routable_vpc.id   
  }
    tags        = merge(local.default_tags, { "Name" = "${local.name_prefix}aws-adconnector" })   
}

// Creating IAM roles and policy
resource "aws_iam_role" "sftp" {
  name = "transfer-server-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })

  tags = merge(local.default_tags, {
    Name = "transfer-server-iam-role"
  })
}

data "aws_iam_policy_document" "sftp" {
  statement {
    sid       = "AllowFullAccesstoCloudWatchLogs"
    effect    = "Allow"
    resources = ["*"]
    actions = [
                "logs:*"
    ]
  }
  statement {
    sid       = "sftps3bucketaccess"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${aws_s3_bucket.sftp.bucket}"]
    actions = [ 
              "s3:ListBucket",
              "s3:GetBucketLocation" 
              ]
  }
  statement {
    sid       = "transferfamilys3access"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${aws_s3_bucket.sftp.bucket}/*"]
    actions = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:DeleteObjectVersion",
            "s3:GetObjectVersion",
            "s3:GetObjectACL",
            "s3:PutObjectACL"
          ]
  }  
}
resource "aws_iam_policy" "sftp" {
  name        = "${local.name_prefix}sftp-transferfmly"
  description = "Transfer family access policy"
  policy      = data.aws_iam_policy_document.sftp.json
}
resource "aws_iam_role_policy_attachment" "sftp" {
  policy_arn = aws_iam_policy.sftp.arn
  role       = aws_iam_role.sftp.name
}
// Creating AWS transfer family sftp server
resource "aws_transfer_server" "sftp" {
  endpoint_type = "VPC"

  endpoint_details {
    subnet_ids = local.snets.routable_app.ids
    vpc_id     = local.routable_vpc.id
    security_group_ids = [aws_security_group.sftp.id]
  }
  protocols   = ["SFTP"]
  identity_provider_type = "AWS_DIRECTORY_SERVICE"
  logging_role           = aws_iam_role.sftp.arn
  directory_id           = aws_directory_service_directory.this.id
  tags        = merge(local.default_tags, { "Name" = "${local.name_prefix}aws-transferfmlyx" })      
}

// Adding access to the AD group using SID
resource "aws_transfer_access" "sftp" {
  external_id    =  var.infrastructure_dependencies.dns.adexternal.external_id
  server_id      = aws_transfer_server.sftp.id
  role           = aws_iam_role.sftp.arn
  home_directory = "/${aws_s3_bucket.sftp.id}/"
}

/* resource "aws_transfer_workflow" "sftp" {
  steps {
    copy_step_details {
      name                 = "example"
      destination_file_location  = "$${original.file}"
      overwrite_existing         = "False"
      source_file_location       = "$${original.file}"
        S3FileLocation: { 
                  Bucket = string
                  Key    = string
               }
    }
    type = "COPY"
  tags        = merge(local.default_tags, { "Name" = "${local.name_prefix}aws-trsfworkflow" }) 
  }
} */