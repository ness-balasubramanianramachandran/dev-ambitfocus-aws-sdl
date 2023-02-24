# These Lambdas will be deployed from Artifactory with Harness. 
# Naming will follow the pattern "cpo-backend-{action}"

##################################################################################################

//CloudWatch log groups
resource "aws_cloudwatch_log_group" "cpo_backend_step_function" {
  name              = "/aws/vendedlogs/states/${local.name_prefix}cpo-backend-step-function"
  retention_in_days = local.log_retention_days

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}cpo-backend-step-function"
  })
}

resource "aws_cloudwatch_log_group" "cpo_backend_lambdas" {
  for_each = toset(local.step_function_lambdas[*].name)

  name              = "/aws/lambda/${each.key}"
  retention_in_days = local.log_retention_days

  tags = merge(local.default_tags, {
    Name = each.key
  })
}

##################################################################################################

// Lambda IAM
resource "aws_iam_role" "cpo_backend_lambda" {
  name = "${local.name_prefix}cpo-backend-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}cpo-backend-lambda"
  })
}

resource "aws_iam_policy" "cpo_backend_lambda" {
  name   = "${local.name_prefix}cpo-backend-lambda"
  policy = data.aws_iam_policy_document.cpo_backend_lambda.json

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}cpo-backend-lambda"
  })
}
resource "aws_iam_role_policy_attachment" "cpo_backend_lambda" {
  role       = aws_iam_role.cpo_backend_lambda.name
  policy_arn = aws_iam_policy.cpo_backend_lambda.arn
}

##################################################################################################

resource "aws_security_group" "cpo_backend_lambda" {
  name        = "${local.name_prefix}cpo-backend-lambda-sg"
  description = "Egress for communication with EKS and AWS APIs"
  vpc_id      = local.nr_vpc.id

  egress {
    description      = "Allows response from Backend Lambda with EKS and AWS APIs"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags,
    {
      Name = "${local.name_prefix}cpo-backend-lambda-sg"
  })
}


##################################################################################################
# Step Function
##################################################################################################
resource "aws_iam_role" "cpo_backend_step_function" {
  name = "${local.name_prefix}cpo-backend-step-function"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}cpo-backend-step-function"
  })
}

resource "aws_iam_policy" "cpo_backend_step_function" {
  name = "${local.name_prefix}cpo-backend-step-function"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = local.step_function_lambdas[*].arn
      },
      {
        Sid = "logging"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = ["${aws_cloudwatch_log_group.cpo_backend_step_function.arn}:log-stream:*"]
      },
      # per https://docs.aws.amazon.com/step-functions/latest/dg/cw-logs.html
      {
        Sid = "loggingSetup"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}cpo-backend-step-function"
  })
}

resource "aws_iam_role_policy_attachment" "cpo_backend_step_function" {
  role       = aws_iam_role.cpo_backend_step_function.name
  policy_arn = aws_iam_policy.cpo_backend_step_function.arn
}

resource "aws_sfn_state_machine" "cpo_backend_step_function" {
  name = "${local.name_prefix}cpo-backend-step-function"

  role_arn = aws_iam_role.cpo_backend_step_function.arn
  definition = templatefile("${path.module}/templates/step_function_definition.tpl",
    {
      // arn:{partition}:lambda:{region}:{account}:function:{function_name}
      CREATE_NAMESPACE_LAMBDA_ARN         = "arn:${data.aws_partition.current.id}:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${local.name_prefix}cpo-backend-create-namespace",
      CREATE_NAMESPACE_SECRETS_LAMBDA_ARN = "arn:${data.aws_partition.current.id}:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${local.name_prefix}cpo-backend-create-namespace-secrets",
      DEPLOY_ROUTER_LAMBDA_ARN            = "arn:${data.aws_partition.current.id}:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${local.name_prefix}cpo-backend-deploy-router",
      CREATE_ROUTER_SERVICE_LAMBDA_ARN    = "arn:${data.aws_partition.current.id}:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${local.name_prefix}cpo-backend-create-router-service",
      DEPLOY_CALC_ENGINE_ARN              = "arn:${data.aws_partition.current.id}:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${local.name_prefix}cpo-backend-deploy-calc-engine",
      EVALUATE_HEARTBEAT_STATUS_ARN       = "arn:${data.aws_partition.current.id}:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${local.name_prefix}cpo-backend-evaluate-heartbeat-status",
      TEARDOWN_ARN                        = "arn:${data.aws_partition.current.id}:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${local.name_prefix}cpo-backend-teardown",
    }
  )

  type = "STANDARD"

  logging_configuration {
    level                  = "ALL"
    include_execution_data = false
    log_destination        = "${aws_cloudwatch_log_group.cpo_backend_step_function.arn}:*"
  }

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}cpo-backend-step-function"
  })
}

##################################################################################################
# SQS DLQ and KMS CMK access role

resource "aws_iam_policy" "cpo_sqs_kms" {
  name   = "${local.name_prefix}-lambda-sqs-dlq-kms"
  policy = data.aws_iam_policy_document.cpo_sqs_kms.json
  tags = merge(local.default_tags, { "Name" = "${local.name_prefix}kms-sqs-dlq" })
}

resource "aws_iam_role_policy_attachment" "cpo_sqs_kms" {
  role       = aws_iam_role.cpo_backend_step_function.name
  policy_arn = aws_iam_policy.cpo_sqs_kms.arn
}

##################################################################################################
# Step Function Cloudwatch Alarms

resource "aws_cloudwatch_metric_alarm" "executions_failed" {
  alarm_name          = "${aws_sfn_state_machine.cpo_backend_step_function.name}/executions-failed"
  alarm_description   = "Step Function ExecutionsFailed"
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  period              = 60
  namespace           = "AWS/States"
  metric_name         = "ExecutionsFailed"
  statistic           = "Sum"
  dimensions = {
    StateMachineArn = aws_sfn_state_machine.cpo_backend_step_function.arn
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "ignore"

  # TODO: pass in SNS topic ARNs once escalation procedures are defined
  # alarm_actions             = []
  # ok_actions                = []
  # insufficient_data_actions = []

  tags = merge(local.default_tags, {
    Name = "${aws_sfn_state_machine.cpo_backend_step_function.name}/executions-failed"
  })
}

resource "aws_cloudwatch_metric_alarm" "executions_timedout" {
  alarm_name          = "${aws_sfn_state_machine.cpo_backend_step_function.name}/executions-timedout"
  alarm_description   = "Step Function ExecutionsTimedOut"
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  period              = 60
  namespace           = "AWS/States"
  metric_name         = "ExecutionsTimedOut"
  statistic           = "Sum"
  dimensions = {
    StateMachineArn = aws_sfn_state_machine.cpo_backend_step_function.arn
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "ignore"

  # TODO: pass in SNS topic ARNs once escalation procedures are defined
  # alarm_actions             = []
  # ok_actions                = []
  # insufficient_data_actions = []

  tags = merge(local.default_tags, {
    Name = "${aws_sfn_state_machine.cpo_backend_step_function.name}/executions-timedout"
  })
}

##################################################################################################
# Step Function Lambda Cloudwatch Alarms

resource "aws_cloudwatch_metric_alarm" "cpo_backend_lambda_function_time" {
  for_each = { for x in local.step_function_lambdas : x.name => x }

  alarm_name          = "${aws_sfn_state_machine.cpo_backend_step_function.name}/${each.value.name}/LambdaFunctionTime"
  alarm_description   = "Step Function Lambda ${each.value.name} LambdaFunctionTime"
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  period              = 60
  namespace           = "AWS/States"
  metric_name         = "LambdaFunctionTime"
  extended_statistic  = "p99"
  dimensions = {
    LambdaFunctionArn = each.value.arn
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10000
  treat_missing_data  = "ignore"

  # TODO: pass in SNS topic ARNs once escalation procedures are defined
  # alarm_actions             = []
  # ok_actions                = []
  # insufficient_data_actions = []

  tags = merge(local.default_tags, {
    Name = "${aws_sfn_state_machine.cpo_backend_step_function.name}/${each.value.name}/LambdaFunctionTime"
  })
}

resource "aws_cloudwatch_metric_alarm" "cpo_backend_lambda_function_timeout" {
  for_each = { for x in local.step_function_lambdas : x.name => x }

  alarm_name          = "${aws_sfn_state_machine.cpo_backend_step_function.name}/${each.value.name}/LambdaFunctionsTimedOut"
  alarm_description   = "Step Function Lambda ${each.value.name} LambdaFunctionsTimedOut"
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  period              = 60
  namespace           = "AWS/States"
  metric_name         = "LambdaFunctionsTimedOut"
  statistic           = "Sum"
  dimensions = {
    LambdaFunctionArn = each.value.arn
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "ignore"

  # TODO: pass in SNS topic ARNs once escalation procedures are defined
  # alarm_actions             = []
  # ok_actions                = []
  # insufficient_data_actions = []

  tags = merge(local.default_tags, {
    Name = "${aws_sfn_state_machine.cpo_backend_step_function.name}/${each.value.name}/LambdaFunctionsTimedOut"
  })
}

resource "aws_cloudwatch_metric_alarm" "cpo_backend_lambda_function_failed" {
  for_each = { for x in local.step_function_lambdas : x.name => x }

  alarm_name          = "${aws_sfn_state_machine.cpo_backend_step_function.name}/${each.value.name}/LambdaFunctionsFailed"
  alarm_description   = "Step Function Lambda ${each.value.name} LambdaFunctionsFailed"
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  period              = 60
  namespace           = "AWS/States"
  metric_name         = "LambdaFunctionsFailed"
  statistic           = "Sum"
  dimensions = {
    LambdaFunctionArn = each.value.arn
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "ignore"

  # TODO: pass in SNS topic ARNs once escalation procedures are defined
  # alarm_actions             = []
  # ok_actions                = []
  # insufficient_data_actions = []

  tags = merge(local.default_tags, {
    Name = "${aws_sfn_state_machine.cpo_backend_step_function.name}/${each.value.name}/LambdaFunctionsFailed"
  })
}

##########################################################
### Vault resources for compute platform orchestration
##########################################################

resource "vault_policy" "compute_platform_orchestration" {
  provider = vault.bsmi
  name     = "${local.name_prefix}bsmi-compute-platform-orchestration"
  policy   = <<EOT
path "bsmi-${var.environment_code}-kv/data/harness/svcacct_arpart_ro" {
  capabilities = ["read"]
}
path "bsmi-${var.environment_code}-kv/data/calc-engine-ssl-cert" {
  capabilities = ["read"]
}
EOT
}

resource "vault_aws_auth_backend_role" "compute_platform_orchestration" {
  provider                 = vault.bsmi
  backend                  = "aws"
  role                     = "${local.name_prefix}bsmi-compute-platform-orchestration"
  auth_type                = "iam"
  bound_iam_principal_arns = [aws_iam_role.cpo_backend_lambda.arn]
  token_ttl                = 600
  token_max_ttl            = 1200
  token_policies           = [vault_policy.compute_platform_orchestration.name]
}