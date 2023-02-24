resource "aws_iam_role" "file_gateway_share" {
  name = "file-gateway-share-role"

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
resource "aws_security_group" "transfer_family" {
  name        = "${local.name_prefix}transfer-family"
  description = "Security group for the file gateway."
  vpc_id      = local.routable_vpc.id

  tags = merge(local.default_tags, { "Name" = "${local.name_prefix}transfer-family" })
}
resource "aws_security_group" "storage_gateway" {
  name        = "${local.name_prefix}storage-gateway"
  description = "Security group for the storage gateway."
  vpc_id      = local.routable_vpc.id
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.routable_vpc.cidr_block]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 1026
    to_port     = 1026
    protocol    = "tcp"
    cidr_blocks = [local.routable_vpc.cidr_block]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 1027
    to_port     = 1027
    protocol    = "tcp"
    cidr_blocks = [local.routable_vpc.cidr_block]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 1028
    to_port     = 1028
    protocol    = "tcp"
    cidr_blocks = [local.routable_vpc.cidr_block]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 1031
    to_port     = 1031
    protocol    = "tcp"
    cidr_blocks = [local.routable_vpc.cidr_block]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = [local.routable_vpc.cidr_block]
  }
  tags = merge(local.default_tags, { "Name" = "${local.name_prefix}storage-gateway" })
}
/*data "aws_vpc_endpoint_service" "storagegateway" {
  service      = "storagegateway"
}*/
data "aws_vpc_endpoint_service" "s3" {
  service      = "s3"
  service_type = "Gateway"
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = local.routable_vpc.id
  service_name      = data.aws_vpc_endpoint_service.s3.service_name
  vpc_endpoint_type = "Interface"
}
/*resource "aws_vpc_endpoint" "storage_gateway" {
  vpc_id              = local.routable_vpc.id
  service_name        = data.aws_vpc_endpoint_service.storagegateway.service_name
  private_dns_enabled = false
  subnet_ids          = local.snets.routable_app.ids
  security_group_ids  = [aws_security_group.storage_gateway.id]
  tags                = merge(local.default_tags, {
    Name = "${local.name_prefix}storage-gateway-endpoint"
  })
}*/
resource "aws_instance" "transfer_family" {
  ami           = local.file_gateway_ami
  instance_type = local.file_gateway_instance_type
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.transfer_family.id]
  subnet_id              = local.snets.routable_app.ids[0]
  tags = merge(local.default_tags, local.ec2_tags, {
    Name = "vwawsbsmitf${var.environment_code}01"
  })
}
resource "aws_storagegateway_gateway" "transfer_family" {
  gateway_name       = "transfer-family"
  gateway_timezone   = local.file_gateway_timezone
  gateway_ip_address = aws_instance.transfer_family.private_ip
  #gateway_vpc_endpoint = aws_vpc_endpoint.storage_gateway.id
  gateway_type = "FILE_S3"
}
resource "aws_storagegateway_smb_file_share" "transfer_family" {
  authentication        = "ActiveDirectory"
  gateway_arn           = aws_storagegateway_gateway.transfer_family.arn
  location_arn          = aws_s3_bucket.sftp.arn
  vpc_endpoint_dns_name = aws_vpc_endpoint.s3.dns_entry[0]["dns_name"]
  role_arn              = aws_iam_role.file_gateway_share.arn
}
