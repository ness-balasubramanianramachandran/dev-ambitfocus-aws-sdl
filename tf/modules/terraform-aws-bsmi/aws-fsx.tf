resource "aws_security_group" "fsx_fileshare" {
  name        = "${local.name_prefix}fsx-fileshare"
  description = "Security group for the fsx fileshare"
  vpc_id      = local.routable_vpc.id
  tags        = merge(local.default_tags, { "Name" = "${local.name_prefix}fsx-fileshare" })
}

// create sg rules
resource "aws_security_group_rule" "all_to_fsx_fileshare" {
  description       = "Allow outbound connections from fsx fileshare"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.fsx_fileshare.id
}
resource "aws_security_group_rule" "dc_from_fistofsxfileshare" {
  description       = "Allow inbound connections from FIS domain cotroller(s)"
  type              = "ingress"
  from_port         = 49152
  to_port           = 65535
  protocol          = "TCP"
  security_group_id = aws_security_group.fsx_fileshare.id
  cidr_blocks       = local.ad_cidrs
}
resource "aws_security_group_rule" "dcudp_from_fistofsxfileshare" {
  description       = "Allow inbound connections (UDP) from FIS domain cotroller(s)"
  type              = "ingress"
  from_port         = 49152
  to_port           = 65535
  protocol          = "UDP"
  security_group_id = aws_security_group.fsx_fileshare.id
  cidr_blocks       = local.ad_cidrs
}
resource "aws_security_group_rule" "routable_app" {
  description       = "Allow Routable apps subnets to connect FSX"
  type              = "ingress"
  from_port         = 445
  to_port           = 445
  protocol          = "TCP"
  security_group_id = aws_security_group.fsx_fileshare.id
  cidr_blocks       = local.snets.routable_app.cidrs
}
resource "aws_security_group_rule" "front_end" {
  description       = "Allow Frontend app subnets to connect FSX"
  type              = "ingress"
  from_port         = 445
  to_port           = 445
  protocol          = "TCP"
  security_group_id = aws_security_group.fsx_fileshare.id
  cidr_blocks       = local.snets.routable_front_end.cidrs
}
resource "aws_security_group_rule" "rds_sub" {
  description       = "Allow RDS Subnets to connect FSX"
  type              = "ingress"
  from_port         = 445
  to_port           = 445
  protocol          = "TCP"
  security_group_id = aws_security_group.fsx_fileshare.id
  cidr_blocks       = local.snets.routable_rds.cidrs
}

resource "aws_fsx_windows_file_system" "fsx_fileshare" {
  storage_capacity                = local.infrastructure_instance_type_obj.fileshare.storage_capacity
  subnet_ids                      = [data.aws_subnets.routable_app.ids[0]]
  throughput_capacity             = local.infrastructure_instance_type_obj.fileshare.throughput_capacity
  automatic_backup_retention_days = 0
  kms_key_id                      = aws_kms_key.rds_sql.arn
  security_group_ids              = [aws_security_group.fsx_fileshare.id]


  self_managed_active_directory {
    dns_ips     = var.infrastructure_dependencies.dns.domain_controller_ips
    domain_name = var.infrastructure_dependencies.dns.domains.fisdev-local
    password    = local.focus_ADPASS
    username    = local.focus_ADUSER
  }
  tags = merge(local.default_tags, { "Name" = "${local.name_prefix}fsx-fileshare" })


}