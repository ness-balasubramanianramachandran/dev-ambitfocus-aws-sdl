resource "aws_cloudwatch_metric_alarm" "high_latency" {
  for_each = local.apigw_methods

  alarm_name          = "${aws_api_gateway_rest_api.this.name}${each.value.resource.path}/${each.value.http_method}/high-latency"
  alarm_description   = "Resource high-latency"
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  period              = 60
  namespace           = "AWS/ApiGateway"
  metric_name         = "Latency"
  extended_statistic  = "p99"
  dimensions = {
    ApiName  = aws_api_gateway_rest_api.this.name
    Resource = each.value.resource.path
    Method   = each.value.http_method
    Stage    = aws_api_gateway_stage.prod.stage_name
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = 5000
  treat_missing_data  = "ignore"

  # TODO: pass in SNS topic ARNs once escalation procedures are defined
  # alarm_actions             = []
  # ok_actions                = []
  # insufficient_data_actions = []

  tags = merge(var.fis_tags, {
    Name = replace("${aws_api_gateway_rest_api.this.name}${each.value.resource.path}/${each.value.http_method}/high-latency", "/[{}]/", ":")
  })
}

resource "aws_cloudwatch_metric_alarm" "on_4XXError" {
  for_each = local.apigw_methods

  alarm_name          = "${aws_api_gateway_rest_api.this.name}${each.value.resource.path}/${each.value.http_method}/4XXError"
  alarm_description   = "Resource 4XXError"
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  period              = 60
  namespace           = "AWS/ApiGateway"
  metric_name         = "4XXError"
  statistic           = "Sum"
  dimensions = {
    ApiName  = aws_api_gateway_rest_api.this.name
    Resource = each.value.resource.path
    Method   = each.value.http_method
    Stage    = aws_api_gateway_stage.prod.stage_name
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "ignore"

  # TODO: pass in SNS topic ARNs once escalation procedures are defined
  # alarm_actions             = []
  # ok_actions                = []
  # insufficient_data_actions = []

  tags = merge(var.fis_tags, {
    Name = replace("${aws_api_gateway_rest_api.this.name}${each.value.resource.path}/${each.value.http_method}/4XXError", "/[{}]/", ":")
  })
}

resource "aws_cloudwatch_metric_alarm" "on_5XXError" {
  for_each = local.apigw_methods

  alarm_name          = "${aws_api_gateway_rest_api.this.name}${each.value.resource.path}/${each.value.http_method}/5XXError"
  alarm_description   = "Resource 5XXError"
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  period              = 60
  namespace           = "AWS/ApiGateway"
  metric_name         = "5XXError"
  statistic           = "Sum"
  dimensions = {
    ApiName  = aws_api_gateway_rest_api.this.name
    Resource = each.value.resource.path
    Method   = each.value.http_method
    Stage    = aws_api_gateway_stage.prod.stage_name
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "ignore"

  # TODO: pass in SNS topic ARNs once escalation procedures are defined
  # alarm_actions             = []
  # ok_actions                = []
  # insufficient_data_actions = []

  tags = merge(var.fis_tags, {
    Name = replace("${aws_api_gateway_rest_api.this.name}${each.value.resource.path}/${each.value.http_method}/5XXError", "/[{}]/", ":")
  })
}