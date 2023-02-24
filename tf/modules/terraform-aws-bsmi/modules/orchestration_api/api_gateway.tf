resource "aws_api_gateway_rest_api" "this" {
  name = "${var.name_prefix}orchestration-api-gateway"

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.this.id]
  }

  tags = merge(var.fis_tags,
    {
      Name = "${var.name_prefix}orchestration-api-gateway"
  })
}

data "aws_iam_policy_document" "apigw" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["*"]
  }

  statement {
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.this.id]
    }
  }
}

resource "aws_api_gateway_rest_api_policy" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  policy = data.aws_iam_policy_document.apigw.json
}

##################################################################################################
// iam role for the apigateway to call lambdas

resource "aws_iam_role" "api_gateway_invoke_lambda" {
  name = "${var.name_prefix}api-gateway-invoke-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })

  inline_policy {
    name = "invoke-lambdas"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = "lambda:InvokeFunction"
          Effect   = "Allow"
          Resource = local.apigw_lambdas[*].arn
        }
      ]
    })
  }

  tags = merge(var.fis_tags, {
    Name = "${var.name_prefix}api-gateway-invoke-lambda"
  })
}

##################################################################################################
# api resources

resource "aws_api_gateway_resource" "compute_platform" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "compute-platform"
}

resource "aws_api_gateway_resource" "compute_platform_detail" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.compute_platform.id
  path_part   = "{namespace}"
}

##################################################################################################
# orchestration_start

module "apigw_lambda_proxies" {
  for_each = local.apigw_methods

  source = "../api_gateway_lambda_proxy_method"

  api_gateway_rest_api = aws_api_gateway_rest_api.this
  api_gateway_resource = each.value.resource
  http_method          = each.value.http_method
  authorization        = "NONE"
  lambda_function_name = each.value.lambda_function_name
  execution_role_arn   = aws_iam_role.api_gateway_invoke_lambda.arn

  fis_tags = var.fis_tags
}

##################################################################################################
# deployment config

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    # any changes to this file or naming of resources should result in a redeployment
    redeployment = md5(jsonencode([
      file("${path.module}/api_gateway.tf"),
      var.name_prefix
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access_logs.arn
    format          = "{ \"requestId\":\"$context.requestId\", \"ip\": \"$context.identity.sourceIp\", \"caller\":\"$context.identity.caller\", \"user\":\"$context.identity.user\",\"requestTime\":\"$context.requestTime\", \"httpMethod\":\"$context.httpMethod\",\"resourcePath\":\"$context.resourcePath\", \"status\":\"$context.status\",\"protocol\":\"$context.protocol\", \"responseLength\":\"$context.responseLength\" }"
  }

  depends_on = [
    aws_api_gateway_account.this
  ]

  tags = merge(var.fis_tags, {
    Name = "${var.name_prefix}cpo-api-deployment-prod"
  })
}


##################################################################################################
// enables execution and access logging for api gateway

// NOTE: This is a global resource common to all Api Gateways, so will not be name-prefixed
resource "aws_iam_role" "apigw_cloudwatch" {
  name = "api-gateway-cloudwatch-global"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })

  # using policy per developer guide here: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html
  inline_policy {
    name = "write-cloudwatch-logs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
            "logs:GetLogEvents",
            "logs:FilterLogEvents"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  tags = merge(local.fis_tags, {
    Name = "api-gateway-cloudwatch-global"
  })
}

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch.arn
}

//CloudWatch access log group
resource "aws_cloudwatch_log_group" "access_logs" {
  name              = "/aws/apigateway/access/${aws_api_gateway_rest_api.this.name}"
  retention_in_days = 30

  tags = merge(local.fis_tags, {
    Name = "${var.name_prefix}cpo-api-access-logs"
  })
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    logging_level      = "INFO"
    data_trace_enabled = false
    metrics_enabled    = true
  }
}
