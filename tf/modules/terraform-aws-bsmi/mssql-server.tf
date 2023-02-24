//create Hashicorp Vault role and map it to the Mssql Server instance profile
//this will allow for user data script to authenticate to Vault and pull the credentials for 
//AD admin and Ansible users

resource "vault_aws_auth_backend_role" "mssql_server_vault_role" {
  provider = vault.bsmi

  backend                         = "aws"
  role                            = "${local.name_prefix}bsmi-mssqlserver"
  auth_type                       = "iam"
  bound_iam_instance_profile_arns = [aws_iam_instance_profile.mssql_server.arn]
  inferred_entity_type            = "ec2_instance"
  inferred_aws_region             = data.aws_region.current.name
  token_ttl                       = 600
  token_max_ttl                   = 1200
  token_policies                  = ["ec2_read"]
}

//create mssql Server security group
resource "aws_security_group" "mssql_server" {
  name        = "${local.name_prefix}mssql-server"
  description = "Security group for the mssql Server(s)"
  vpc_id      = local.routable_vpc.id

  tags = merge(local.default_tags, local.ec2_tags, { "Name" = "${local.name_prefix}mssql-server" })

}
// create sg rules
resource "aws_security_group_rule" "all_to_worldfrommssqlserver" {
  description       = "Allow outbound connections from MsSQL Server"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mssql_server.id
}
resource "aws_security_group_rule" "rdp_to_sql" {
  description       = "Allow RDP to MsSQL Server"
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "TCP"
  security_group_id = aws_security_group.mssql_server.id
  cidr_blocks       = var.infrastructure_dependencies.access.rdp_cidrs
}
resource "aws_security_group_rule" "dc_from_fistomssqlserver" {
  description       = "Allow inbound connections from FIS domain cotroller(s)"
  type              = "ingress"
  from_port         = 49152
  to_port           = 65535
  protocol          = "TCP"
  security_group_id = aws_security_group.mssql_server.id
  cidr_blocks       = local.ad_cidrs
}
resource "aws_security_group_rule" "dcudp_from_fistomssqlserver" {
  description       = "Allow inbound connections (UDP) from FIS domain cotroller(s)"
  type              = "ingress"
  from_port         = 49152
  to_port           = 65535
  protocol          = "UDP"
  security_group_id = aws_security_group.mssql_server.id
  cidr_blocks       = local.ad_cidrs
}
resource "aws_security_group_rule" "winrm_from_eks_computetomssqlserver" {
  description       = "Allow inbound http WinRM connections from Harness Delegate pod"
  type              = "ingress"
  from_port         = 5985
  to_port           = 5985
  protocol          = "TCP"
  security_group_id = aws_security_group.mssql_server.id
  cidr_blocks       = local.snets.nr_compute.cidrs
}
resource "aws_security_group_rule" "winrm_https_from_eks_computetomssqlserver" {
  description       = "Allow inbound https WinRM connections from Harness Delegate pod"
  type              = "ingress"
  from_port         = 5986
  to_port           = 5986
  protocol          = "TCP"
  security_group_id = aws_security_group.mssql_server.id
  cidr_blocks       = local.snets.nr_compute.cidrs
}

//Allow  connection to  enable SSAS
resource "aws_security_group_rule" "mssql_server_to_enable_ssas" {
  description              = "Enables SSAS on MSSQL Server"
  type                     = "ingress"
  from_port                = 2383
  to_port                  = 2383
  protocol                 = "TCP"
  security_group_id        = aws_security_group.mssql_server.id
  source_security_group_id = aws_security_group.application_server.id
}
resource "aws_security_group_rule" "mssql_from_app_servers" {
  description              = "Allows incoming traffic from Application server"
  type                     = "ingress"
  from_port                = 2433
  to_port                  = 2433
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.application_server.id
  security_group_id        = aws_security_group.mssql_server.id
}
resource "aws_security_group_rule" "mssql_from_eks" {
  description       = "Allows incoming traffic from EKS Cluster"
  type              = "ingress"
  from_port         = 2433
  to_port           = 2433
  protocol          = "tcp"
  cidr_blocks       = local.snets.nr_compute.cidrs
  security_group_id = aws_security_group.mssql_server.id
}

//Create IAM instance profile
data "aws_iam_policy_document" "mssql_server_assume_role" {
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

resource "aws_iam_role" "mssql_server" {
  name                  = "${local.name_prefix}mssql-server"
  assume_role_policy    = data.aws_iam_policy_document.application_server_assume_role.json
  force_detach_policies = true
  tags                  = merge(local.default_tags, { "Name" = "${local.name_prefix}mssql-server" })
}

resource "aws_iam_instance_profile" "mssql_server" {
  name = "${local.name_prefix}mssql-server"
  role = aws_iam_role.mssql_server.name

  tags = merge(local.default_tags, { "Name" = "${local.name_prefix}mssql-server" })
  lifecycle {
    create_before_destroy = true
  }
}

//create mssql server EC2 instance
resource "aws_instance" "mssql_server" {
  ami           = local.mssql_server_ami
  instance_type = local.infrastructure_instance_type_obj.selfmanaged_db.instance_type
  root_block_device {
    encrypted  = true
    kms_key_id = aws_kms_key.eks_ebs.arn
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  monitoring = true
  user_data_base64 = base64encode(
    templatefile(
      "${path.module}/templates/mssql_server_ppscript.tpl",
      merge(local.mssql_server_userdata_params, { VMNAME = "${local.mssql_server_instance_prefix}1" })
    )
  )

  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.mssql_server.id]
  subnet_id                   = local.snets.routable_app.ids[0]
  iam_instance_profile        = aws_iam_instance_profile.mssql_server.name

  tags = merge(
    local.default_tags,
    local.ec2_tags,
    {
      "Name"           = "${local.mssql_server_instance_prefix}1",
      "BSMIComponents" = "sqlserver"
    }
  )

  depends_on = [
    vault_aws_auth_backend_role.mssql_server_vault_role
  ]
}
data "aws_instance" "mssql_server" {
  instance_id = aws_instance.mssql_server.id
}
resource "aws_ebs_volume" "sqldb" {
  availability_zone = data.aws_instance.mssql_server.availability_zone
  size              = local.infrastructure_instance_type_obj.selfmanaged_db.allocated_storage
  encrypted         = true
  kms_key_id        = aws_kms_key.eks_ebs.arn

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}sqldb",
    }
  )
}
resource "aws_volume_attachment" "sqldb" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.sqldb.id
  instance_id = aws_instance.mssql_server.id
}
