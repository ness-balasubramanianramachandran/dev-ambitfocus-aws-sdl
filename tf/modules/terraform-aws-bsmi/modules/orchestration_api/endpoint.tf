
data "aws_vpc_endpoint_service" "execute_api" {
  service = "execute-api"
}

resource "aws_security_group" "gateway_endpoint" {
  name        = "${var.name_prefix}orchestration-gateway-endpoint-sg"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = var.nr_vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat([
      var.nr_vpc.cidr_block,
      var.vpc_access.cidr_block
      ],
      var.nr_vpc.cidr_block_associations[*].cidr_block,
      var.vpc_access.cidr_block_associations[*].cidr_block,
    )
  }

  egress {
    description = "Allows response to FIS network and AWS APIs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.fis_tags, {
    Name = "${var.name_prefix}orchestration-gateway-endpoint-sg"
  })
}

resource "aws_vpc_endpoint" "this" {
  vpc_id              = var.nr_vpc.id
  service_name        = data.aws_vpc_endpoint_service.execute_api.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = false

  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.gateway_endpoint.id]

  tags = merge(var.fis_tags, {
    Name = "${var.name_prefix}orchestration-api-gateway-endpoint"
  })
}