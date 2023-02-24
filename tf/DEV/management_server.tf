locals {
  environment_code                = module.bsmi.environment_code
  name_prefix                     = "${local.environment_code}-"
  management_server_ami           = "ami-013827243f5b07ffc"
  management_server_instance_type = "t3.medium"
  management_server_userdata_params = {
    VAULT_DOWNLOAD_URL = "https://releases.hashicorp.com/vault/1.11.2/vault_1.11.2_windows_amd64.zip"
    VAULT_SERVER       = "vamazhashivault.fisdev.local"
    VAULT_NAMESPACE    = "AMBIT-FOCUS"
    VAULT_ROLE         = "${local.name_prefix}bsmi-mgmt-server"
    VAULT_KV           = "bsmi-${local.environment_code}-kv"
    ANSIBLE_USER       = "ansible"
    VMNAME             = "vwawsbsmims${local.environment_code}11"
    DC_HOST            = "VWAWSNVDC01.fisdev.local"
    DC_FULLOUPATH      = "OU=AMBIT_FOCUS,OU=AWS_NorthVirginia,OU=AWS,DC=fisdev,DC=local"
    DC_DOMAIN          = "FISDEV.LOCAL"
  }
  management_server_userdata_base64 = base64encode(
    templatefile("${path.module}/templates/management_server_userdata.tpl", local.management_server_userdata_params)
  )

  routable_front_end_cidrs = module.bsmi.snets.routable_front_end.cidrs

  ad_cidrs = [
    "${local.infrastructure_dependencies.dns.domain_controller_ips[0]}/32",
    "${local.infrastructure_dependencies.dns.domain_controller_ips[1]}/32"
  ]
  default_tags = module.bsmi.default_tags
  ec2_tags     = module.bsmi.ec2_tags
}
resource "vault_aws_auth_backend_role" "mgmt_server_vault_role" {
  provider = vault.bsmi

  backend                         = "aws"
  role                            = "${local.name_prefix}bsmi-mgmt-server"
  auth_type                       = "iam"
  bound_iam_instance_profile_arns = [aws_iam_instance_profile.management_server.arn]
  inferred_entity_type            = "ec2_instance"
  inferred_aws_region             = data.aws_region.current.name
  token_ttl                       = 600
  token_max_ttl                   = 1200
  token_policies                  = ["ec2_read"]
}
//create management server security group
resource "aws_security_group" "management_server" {
  name        = "${local.name_prefix}mgmt-server"
  description = "Security group for the Management Server"
  vpc_id      = data.aws_vpc.routable_vpc.id

  tags = merge(local.default_tags, local.ec2_tags, { "Name" = "${local.name_prefix}mgmt-server" })
}

// create sg rules
resource "aws_security_group_rule" "all_to_world" {
  description       = "Allow outbound connections from Management Server"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.management_server.id
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "rdp_from_fis" {
  description       = "Allow RDP from FIS network CIDRs"
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "TCP"
  security_group_id = aws_security_group.management_server.id
  cidr_blocks       = local.infrastructure_dependencies.access.rdp_cidrs
}
resource "aws_security_group_rule" "dc_from_fis" {
  description       = "Allow inbound connections from FIS domain cotroller(s)"
  type              = "ingress"
  from_port         = 49152
  to_port           = 65535
  protocol          = "TCP"
  security_group_id = aws_security_group.management_server.id
  cidr_blocks       = local.ad_cidrs
}
resource "aws_security_group_rule" "dcudp_from_fis" {
  description       = "Allow inbound connections (UDP) from FIS domain cotroller(s)"
  type              = "ingress"
  from_port         = 49152
  to_port           = 65535
  protocol          = "UDP"
  security_group_id = aws_security_group.management_server.id
  cidr_blocks       = local.ad_cidrs
}
//allow Management Server to connect to EKS API
resource "aws_security_group_rule" "https_from_management_server" {
  description       = "Allow Management Server to connect to EKS api server"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = module.bsmi.eks_api_sg_id
  cidr_blocks       = local.routable_front_end_cidrs
}
//allow Management Server to connect to Application Sercver(s)
resource "aws_security_group_rule" "rdp_from_management_server" {
  description              = "Allow RDP from Management Server to Application Server"
  type                     = "ingress"
  from_port                = 3389
  to_port                  = 3389
  protocol                 = "TCP"
  security_group_id        = module.bsmi.app_server_sg_id
  source_security_group_id = aws_security_group.management_server.id
}
//Allow  connection to  enable SSAS
resource "aws_security_group_rule" "mgmt_to_sql_ssas" {
  description              = "Enables SSAS on MSSQL Server"
  type                     = "ingress"
  from_port                = 2383
  to_port                  = 2383
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.management_server.id
  security_group_id        = module.bsmi.sql_server_sg_id
}
resource "aws_security_group_rule" "mgmt_to_sqlserver" {
  description              = "Connection to MSSQL Server"
  type                     = "ingress"
  from_port                = 2433
  to_port                  = 2433
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.management_server.id
  security_group_id        = module.bsmi.sql_server_sg_id
}

//Create IAM instance profile
data "aws_iam_policy_document" "management_server_assume_role" {
  statement {
    sid = "ManagementServerAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

// TODO: define IAM policy for the Management Server instance
//data "aws_iam_policy_document" "management_server" {
//  statement {
//    sid       = ""
//    effect    = "Allow"
//    resources = [""]
//
//    actions = [
//    ]
//  }
//  statement {
//    sid       = ""
//    effect    = "Allow"
//    resources = [""]
//
//    actions = [
//    ]
//  }
//}
//resource "aws_iam_policy" "management_server" {
//  name        = "${local.name_prefix}mgmt-server"
//  description = ""
//  policy      = data.aws_iam_policy_document.management_server.json
//}

resource "aws_iam_role" "management_server" {
  name                  = "${local.name_prefix}mgmt-server"
  assume_role_policy    = data.aws_iam_policy_document.management_server_assume_role.json
  force_detach_policies = true
  tags                  = merge(local.default_tags, { "Name" = "${local.name_prefix}mgmt-server" })
}
//resource "aws_iam_role_policy_attachment" "management_server" {
//  policy_arn = aws_iam_policy.management_server.arn
//  role       = aws_iam_role.management_server.name
//}
resource "aws_iam_instance_profile" "management_server" {
  name = "${local.name_prefix}management_server"
  role = aws_iam_role.management_server.name

  tags = merge(local.default_tags, { "Name" = "${local.name_prefix}mgmt-server" })
  lifecycle {
    create_before_destroy = true
  }
}
//create management server EC2 instance
resource "aws_instance" "management_server" {
  ami           = local.management_server_ami
  instance_type = local.management_server_instance_type
  root_block_device {
    encrypted = true
  }
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
  monitoring                  = true
  user_data_base64            = local.management_server_userdata_base64
  vpc_security_group_ids      = [aws_security_group.management_server.id]
  subnet_id                   = module.bsmi.snets.routable_front_end.ids[0]
  iam_instance_profile        = aws_iam_instance_profile.management_server.name
  user_data_replace_on_change = true

  tags = merge(local.default_tags, local.ec2_tags, { "Name" = local.management_server_userdata_params.VMNAME })
  depends_on = [
    vault_aws_auth_backend_role.mgmt_server_vault_role
  ]
}
