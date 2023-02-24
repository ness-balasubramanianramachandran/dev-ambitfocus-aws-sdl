resource "aws_security_group" "outbound_resolver" {
  name        = "bsmi-outbound-resolver"
  description = "Allow DNS queries from the Route53 outbound resolver"
  vpc_id      = local.routable_vpc.id
  egress {
    description = "Egress TCP 53"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Egress UDP 53"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.default_tags, {
    Name = "bsmi-outbound-resolver"
  })
}

resource "aws_route53_resolver_endpoint" "outbound" {
  name      = "bsmi-resolver"
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.outbound_resolver.id
  ]

  dynamic "ip_address" {
    for_each = toset(local.snets.routable_front_end.ids)
    content {
      subnet_id = ip_address.value
    }
  }

  tags = merge(local.default_tags, {
    Name = "bsmi-resolver"
  })
}

resource "aws_route53_resolver_rule" "outbound" {
  for_each             = var.infrastructure_dependencies.dns.domains
  name                 = each.key
  domain_name          = each.value
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  dynamic "target_ip" {
    for_each = toset(var.infrastructure_dependencies.dns.domain_controller_ips)
    content {
      ip = target_ip.value
    }
  }

  tags = merge(local.default_tags, {
    Name = each.key
  })
}

resource "aws_route53_resolver_rule_association" "routable_outbound" {
  for_each         = aws_route53_resolver_rule.outbound
  resolver_rule_id = each.value.id
  vpc_id           = local.routable_vpc.id
}

resource "aws_route53_resolver_rule_association" "nonroutable_outbound" {
  for_each         = aws_route53_resolver_rule.outbound
  resolver_rule_id = each.value.id
  vpc_id           = local.nr_vpc.id
}

// External DNS Service Discovery
resource "aws_route53_zone" "service_discovery" {
  name    = "svc.cluster.local"
  comment = "Private zone for calc engine service discovery"

  vpc {
    vpc_id = local.routable_vpc.id
  }

  tags = merge(local.default_tags, {
    Name = "svc.cluster.local"
  })
}

// minimize the TTL of negative caching results
// https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html#SOArecords
resource "aws_route53_record" "service_discovery_soa" {
  allow_overwrite = true // record exists when zone is created, so force overwriting it
  zone_id         = aws_route53_zone.service_discovery.id
  name            = aws_route53_zone.service_discovery.name
  type            = "SOA"
  ttl             = 1 // configure as 1 second to minimize negative caching time
  records = [
    "${aws_route53_zone.service_discovery.name_servers[0]} awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
  ]
}

resource "aws_iam_policy" "external_dns" {
  name        = "${local.name_prefix}ExternalDNS-ServiceDiscovery"
  description = "Allows external-dns to manage Route53 hosted zone for calc engine service discovery"
  policy      = data.aws_iam_policy_document.external_dns.json

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}ExternalDNS-ServiceDiscovery"
  })
}
