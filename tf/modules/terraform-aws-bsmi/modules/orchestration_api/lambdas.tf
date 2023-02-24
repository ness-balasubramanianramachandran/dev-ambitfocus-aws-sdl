# These Lambdas will be deployed from Artifactory with Harness. 
# Naming will follow the pattern "cpo-api-{action}"

##################################################################################################

// CloudWatch log groups
resource "aws_cloudwatch_log_group" "apigw_lambdas" {
  for_each = toset(local.apigw_lambdas[*].name)

  name              = "/aws/lambda/${each.key}"
  retention_in_days = local.log_retention_days

  tags = merge(local.fis_tags, {
    Name = each.key
  })
}

##################################################################################################

// Lambda IAM
resource "aws_iam_policy" "orchestration_lambda" {
  name   = "${var.name_prefix}cpo-api-lambda"
  policy = data.aws_iam_policy_document.cpo_api_lambda.json

  tags = merge(var.fis_tags,
    {
      Name = "${var.name_prefix}cpo_api_lambda"
  })
}
resource "aws_iam_role_policy_attachment" "orchestration_api_lambda" {
  role       = var.orchestration_lambda_role_name
  policy_arn = aws_iam_policy.orchestration_lambda.arn
}

##################################################################################################

resource "aws_security_group" "lambdas" {
  name        = "${var.name_prefix}cpo-api-lambda-sg"
  description = "Egress for communication with EKS and AWS APIs"
  vpc_id      = var.nr_vpc.id

  egress {
    description      = "Allows response to EKS Cluster and AWS APIs"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.fis_tags,
    {
      Name = "${var.name_prefix}cpo-api-lambda-sg"
  })
}

##################################################################################################

