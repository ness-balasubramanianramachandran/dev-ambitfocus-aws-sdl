//create Hashicorp Vault role and map it to the App Server instance profile
//this will alllow for user data script to authenticate to Vault and pull the credentials for 
//AD admin and Ansible users
resource "vault_aws_auth_backend_role" "app_server_vault_role" {
  provider = vault.bsmi

  backend                         = "aws"
  role                            = "${local.name_prefix}bsmi-appserver"
  auth_type                       = "iam"
  bound_iam_instance_profile_arns = [aws_iam_instance_profile.application_server.arn]
  inferred_entity_type            = "ec2_instance"
  inferred_aws_region             = data.aws_region.current.name
  token_ttl                       = 600
  token_max_ttl                   = 1200
  token_policies                  = ["ec2_read"]
}

//create Application Server security group
resource "aws_security_group" "application_server" {
  name        = "${local.name_prefix}app-server"
  description = "Security group for the Application Server(s)"
  vpc_id      = local.routable_vpc.id

  tags = merge(local.default_tags, local.ec2_tags, { "Name" = "${local.name_prefix}app-server" })
}

// create sg rules
resource "aws_security_group_rule" "all_to_world" {
  description       = "Allow outbound connections from Application Server"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.application_server.id
}
resource "aws_security_group_rule" "rdp_from_fis" {
  description       = "Allow RDP from FIS network CIDRs"
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "TCP"
  security_group_id = aws_security_group.application_server.id
  cidr_blocks       = var.infrastructure_dependencies.access.rdp_cidrs
}
resource "aws_security_group_rule" "dc_from_fis" {
  description       = "Allow inbound connections from FIS domain cotroller(s)"
  type              = "ingress"
  from_port         = 49152
  to_port           = 65535
  protocol          = "TCP"
  security_group_id = aws_security_group.application_server.id
  cidr_blocks       = local.ad_cidrs
}
resource "aws_security_group_rule" "dcudp_from_fis" {
  description       = "Allow inbound connections (UDP) from FIS domain cotroller(s)"
  type              = "ingress"
  from_port         = 49152
  to_port           = 65535
  protocol          = "UDP"
  security_group_id = aws_security_group.application_server.id
  cidr_blocks       = local.ad_cidrs
}
resource "aws_security_group_rule" "winrm_from_eks_compute" {
  description       = "Allow inbound http WinRM connections from Harness Delegate pod"
  type              = "ingress"
  from_port         = 5985
  to_port           = 5985
  protocol          = "TCP"
  security_group_id = aws_security_group.application_server.id
  cidr_blocks       = local.snets.nr_compute.cidrs
}
resource "aws_security_group_rule" "winrm_https_from_eks_compute" {
  description       = "Allow inbound https WinRM connections from Harness Delegate pod"
  type              = "ingress"
  from_port         = 5986
  to_port           = 5986
  protocol          = "TCP"
  security_group_id = aws_security_group.application_server.id
  cidr_blocks       = local.snets.nr_compute.cidrs
}

//allow Application Server to connect to EKS API
resource "aws_security_group_rule" "https_from_application_server" {
  description       = "Allow Application Server to connect to EKS api server"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = module.eks_cap_dev.cluster_kubernetes_api_security_group_id
  cidr_blocks       = local.snets.routable_app.cidrs
}


//allow Application Server to connect  EKS Cluster
resource "aws_security_group_rule" "http_from_eks_cluster" {
  description       = "Allow inbound http connections from EKS Subnets"
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "TCP"
  security_group_id = aws_security_group.application_server.id
  cidr_blocks       = local.snets.nr_compute.cidrs
}
resource "aws_security_group_rule" "https_from_eks_cluster" {
  description       = "Allow inbound https connections from EKS Subnets"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  security_group_id = aws_security_group.application_server.id
  cidr_blocks       = local.snets.nr_compute.cidrs
}
//Allow  connection to  enable SSAS
resource "aws_security_group_rule" "app_server_to_enable_ssas" {
  description              = "Enables SSAS on MSSQL Server"
  type                     = "ingress"
  from_port                = 2383
  to_port                  = 2383
  protocol                 = "TCP"
  security_group_id        = aws_security_group.application_server.id
  source_security_group_id = aws_security_group.mssql_server.id
}
resource "aws_security_group_rule" "app_from_sql_servers" {
  description              = "Connection from MSSQL Server"
  type                     = "ingress"
  from_port                = 2433
  to_port                  = 2433
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.mssql_server.id
  security_group_id        = aws_security_group.application_server.id
}
resource "aws_security_group_rule" "bsmi_from_eks_compute" {
  description       = "Allow inbound connections from BSMI worker pods"
  type              = "ingress"
  from_port         = 5000
  to_port           = 10000
  protocol          = "TCP"
  security_group_id = aws_security_group.application_server.id
  cidr_blocks       = local.snets.nr_compute.cidrs
}
//Create IAM instance profile
data "aws_iam_policy_document" "application_server_assume_role" {
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

//TODO: define IAM policy for the Application Server instance
data "aws_iam_policy_document" "application_server" {
  statement {
    sid       = "Cloudwatchagentserver"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "logs:*",
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]
  }
  statement {
    sid       = "Cloudwatchssmparameter"
    effect    = "Allow"
    resources = ["arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"]

    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter"
    ]
  }
}
resource "aws_iam_policy" "application_server" {
  name        = "${local.name_prefix}cloudwatch-agent"
  description = ""
  policy      = data.aws_iam_policy_document.application_server.json
}

resource "aws_iam_role" "application_server" {
  name                  = "${local.name_prefix}app-server"
  assume_role_policy    = data.aws_iam_policy_document.application_server_assume_role.json
  force_detach_policies = true
  tags                  = merge(local.default_tags, { "Name" = "${local.name_prefix}app-server" })
}

//CloudWatch access log group
resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/applicationserver/logs/${local.name_prefix}appserver-logs"
  retention_in_days = 30

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}appserver-logs"
  })
}

resource "aws_iam_role_policy_attachment" "application_server" {
  policy_arn = aws_iam_policy.application_server.arn
  role       = aws_iam_role.application_server.name
}
resource "aws_iam_instance_profile" "application_server" {
  name = "${local.name_prefix}application_server"
  role = aws_iam_role.application_server.name

  tags = merge(local.default_tags, { "Name" = "${local.name_prefix}app-server" })
  lifecycle {
    create_before_destroy = true
  }
}
//create Application Server EC2 instance
resource "aws_instance" "application_server" {
  count = local.infrastructure_instance_type_obj.application_server.instance_count

  ami           = local.application_server_ami
  instance_type = local.infrastructure_instance_type_obj.application_server.instance_type
  root_block_device {
    encrypted  = true
    kms_key_id = aws_kms_key.eks_ebs.arn
  }
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
  monitoring = true
  user_data_base64 = base64encode(
    templatefile(
      "${path.module}/templates/application_server_ppscript.tpl",
      merge(local.application_server_userdata_params, { VMNAME = "${local.application_server_instance_prefix}${count.index + 1}" })
    )
  )
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.application_server.id]
  subnet_id                   = data.aws_subnets.routable_app.ids[count.index % 2]
  iam_instance_profile        = aws_iam_instance_profile.application_server.name

  tags = merge(
    local.default_tags,
    local.ec2_tags,
    {
      "Name"           = "${local.application_server_instance_prefix}${count.index + 1}",
      "BSMIComponents" = "${local.infrastructure_instance_type_obj.application_server.bsmi_components[count.index]}"
    }
  )
  depends_on = [
    vault_aws_auth_backend_role.app_server_vault_role
  ]
}
